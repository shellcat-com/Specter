import Darwin
import Foundation
import PTYBridge
import TerminalCore

public struct SessionConfiguration: Sendable {
  public var shell: String
  public var directory: String
  public var helper: String
  public var terminfo: String
  public var scrollback: Int
  public init(
    shell: String? = nil, directory: String? = nil, helper: String? = nil, terminfo: String? = nil,
    scrollback: Int = 10_000
  ) {
    self.shell = shell ?? String(cString: getpwuid(getuid()).pointee.pw_shell)
    self.directory = directory ?? FileManager.default.homeDirectoryForCurrentUser.path
    let executableDirectory = URL(fileURLWithPath: CommandLine.arguments[0])
      .deletingLastPathComponent()
    self.helper = helper ?? executableDirectory.appendingPathComponent("SpecterPTY").path
    self.terminfo =
      terminfo ?? Bundle.main.resourceURL?.appendingPathComponent("terminfo").path ?? ""
    self.scrollback = scrollback
  }
}

public enum SessionState: Sendable, Equatable {
  case idle, starting, running, stopping
  case exited(Int32)
  case failed(String)
}

/// All mutable storage is confined to `queue`; only Sendable callbacks cross it.
public final class Session: @unchecked Sendable {
  private let queue = DispatchQueue(label: "app.specter.session", qos: .userInitiated)
  private let engine: Terminal
  private let configuration: SessionConfiguration
  private var master: Int32 = -1
  private var lifetime: Int32 = -1
  private var helperPID: pid_t = 0
  private var readSource: DispatchSourceRead?
  private var statusSource: DispatchSourceRead?
  private var writeSource: DispatchSourceWrite?
  private var pending: [UInt8] = []
  private var writeOffset = 0
  private var state: SessionState = .idle
  private var publicationScheduled = false
  private var statusBytes: [UInt8] = []
  public let onBell: @Sendable () -> Void
  public let onSnapshot: @Sendable (ScreenSnapshot) -> Void
  public let onState: @Sendable (SessionState) -> Void
  public init(
    configuration: SessionConfiguration, onSnapshot: @escaping @Sendable (ScreenSnapshot) -> Void,
    onState: @escaping @Sendable (SessionState) -> Void, onBell: @escaping @Sendable () -> Void = {}
  ) {
    self.configuration = configuration
    engine = Terminal(scrollbackLimit: configuration.scrollback)
    self.onSnapshot = onSnapshot
    self.onState = onState
    self.onBell = onBell
  }
  public func start() { queue.async { self.launch() } }
  public func send(_ bytes: [UInt8]) { queue.async { self.enqueue(bytes) } }
  public func resize(columns: Int, rows: Int) {
    queue.async {
      self.engine.resize(columns: columns, rows: rows)
      if self.master >= 0 {
        _ = specter_resize(self.master, Int32(self.engine.rows), Int32(self.engine.columns))
      }
      self.publish()
    }
  }
  public func stop() {
    queue.async {
      guard self.state == .running || self.state == .starting else { return }
      self.setState(.stopping)
      if self.lifetime >= 0 {
        var byte: UInt8 = 1
        _ = Darwin.write(self.lifetime, &byte, 1)
      }
      self.closeMaster()
    }
  }
  private func setState(_ value: SessionState) {
    state = value
    onState(value)
  }
  private func launch() {
    guard state == .idle else { return }
    setState(.starting)
    let error = specter_start(
      configuration.helper, configuration.shell, configuration.directory, configuration.terminfo,
      Int32(engine.rows), Int32(engine.columns), &master, &lifetime, &helperPID)
    guard error == 0 else {
      setState(.failed(String(cString: strerror(error))))
      return
    }
    let fd = master
    let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
    source.setEventHandler { [weak self] in self?.readOutput() }
    source.setCancelHandler { Darwin.close(fd) }
    readSource = source
    source.resume()
    let controlFD = lifetime
    let control = DispatchSource.makeReadSource(fileDescriptor: controlFD, queue: queue)
    control.setEventHandler { [weak self] in self?.readStatus() }
    control.setCancelHandler { Darwin.close(controlFD) }
    statusSource = control
    control.resume()
    setState(.running)
    publish()
  }
  private func readOutput() {
    guard master >= 0 else { return }
    var buffer = [UInt8](repeating: 0, count: 32768)
    // Bound each turn so resize, input and shutdown cannot starve under continuous output.
    for _ in 0..<8 {
      let count = Darwin.read(master, &buffer, buffer.count)
      if count > 0 {
        engine.feed(buffer.prefix(count))
        for effect in engine.takeEffects() {
          if case .reply(let bytes) = effect { enqueue(bytes) } else if effect == .bell { onBell() }
        }
      } else if count == 0 || count < 0 && errno == EIO {
        closeMaster()
        engine.finish()
        break
      } else if errno == EINTR {
        continue
      } else {
        break
      }
    }
    publish()
  }
  private func enqueue(_ bytes: [UInt8]) {
    guard master >= 0, state == .running else { return }
    guard pending.count - writeOffset + bytes.count <= 1_048_576 else {
      // Reject one oversized user action atomically, never truncate it into a different command.
      onState(.failed("Input queue is full; paste was not sent."))
      return
    }
    if writeOffset > 0 {
      pending.removeFirst(writeOffset)
      writeOffset = 0
    }
    pending += bytes
    flush()
  }
  private func flush() {
    guard master >= 0 else { return }
    while writeOffset < pending.count {
      let count = pending.withUnsafeBytes { bytes in
        Darwin.write(
          master, bytes.baseAddress!.advanced(by: writeOffset), bytes.count - writeOffset)
      }
      if count > 0 {
        writeOffset += count
      } else if count < 0 && errno == EINTR {
        continue
      } else if count < 0 && errno == EAGAIN {
        if writeSource == nil {
          let source = DispatchSource.makeWriteSource(fileDescriptor: master, queue: queue)
          source.setEventHandler { [weak self] in self?.flush() }
          writeSource = source
          source.resume()
        }
        return
      } else {
        closeMaster()
        return
      }
    }
    pending.removeAll(keepingCapacity: true)
    writeOffset = 0
    writeSource?.cancel()
    writeSource = nil
  }
  private func publish() {
    guard !publicationScheduled else { return }
    publicationScheduled = true
    queue.asyncAfter(deadline: .now() + .milliseconds(8)) { [weak self] in
      guard let self else { return }
      self.publicationScheduled = false
      self.onSnapshot(self.engine.snapshot())
    }
  }
  private func readStatus() {
    guard lifetime >= 0 else { return }
    var bytes = [UInt8](repeating: 0, count: 4)
    let count = Darwin.read(lifetime, &bytes, bytes.count)
    if count > 0 { statusBytes += bytes.prefix(count) }
    if statusBytes.count >= 4 || count == 0 {
      // Drain bytes already written before disposing of the master.
      readOutput()
      closeMaster()
      engine.finish()
      publish()
      let status: Int32 =
        statusBytes.count >= 4
        ? statusBytes.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) } : 0
      setState(.exited(status))
      statusSource?.cancel()
      statusSource = nil
      lifetime = -1
      var helperStatus: Int32 = 0
      while waitpid(helperPID, &helperStatus, 0) < 0 && errno == EINTR {}
      helperPID = 0
    }
  }
  private func closeMaster() {
    writeSource?.cancel()
    writeSource = nil
    readSource?.cancel()
    readSource = nil
    master = -1
    pending.removeAll()
    writeOffset = 0
  }
  deinit {
    readSource?.cancel()
    writeSource?.cancel()
    statusSource?.cancel()
    if helperPID > 0 {
      let pid = helperPID
      DispatchQueue.global().async {
        var status: Int32 = 0
        while waitpid(pid, &status, 0) < 0 && errno == EINTR {}
      }
    }
  }
}
