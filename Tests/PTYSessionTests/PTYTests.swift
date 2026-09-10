import Darwin
import Foundation
import PTYBridge
import Testing

@testable import PTYSession

struct PTYTests {
  private func helper() throws -> String {
    let path = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(
        ".build/debug/SpecterPTY"
      ).path
    guard FileManager.default.isExecutableFile(atPath: path) else {
      throw CocoaError(.fileNoSuchFile)
    }
    return path
  }
  @Test func interactivePTYResizeAndExit() throws {
    var fd: Int32 = -1
    var life: Int32 = -1
    var pid: pid_t = 0
    let result = specter_start(try helper(), "/bin/sh", "/tmp", "", 24, 80, &fd, &life, &pid)
    #expect(result == 0)
    guard result == 0 else { return }
    defer {
      close(fd)
      close(life)
      var status: Int32 = 0
      waitpid(pid, &status, 0)
    }
    #expect(specter_resize(fd, 40, 120) == 0)
    let command = Array("printf '__PTY__'; test -t 0 && printf '__TTY__'; stty size; exit 7\n".utf8)
    _ = command.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) }
    var output = ""
    var bytes = [UInt8](repeating: 0, count: 4096)
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
      var pollfd = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
      if poll(&pollfd, 1, 100) > 0 {
        let n = read(fd, &bytes, bytes.count)
        if n > 0 { output += String(decoding: bytes.prefix(n), as: UTF8.self) } else { break }
      }
    }
    #expect(output.contains("__TTY__"))
    #expect(output.contains("40 120"))
    var status: Int32 = 0
    #expect(read(life, &status, 4) == 4)
    #expect((status >> 8) & 255 == 7)
  }
  @Test func closingLifetimeReapsHelper() throws {
    var fd: Int32 = -1
    var life: Int32 = -1
    var pid: pid_t = 0
    #expect(specter_start(try helper(), "/bin/sh", "/tmp", "", 24, 80, &fd, &life, &pid) == 0)
    guard fd >= 0 else { return }
    close(life)
    close(fd)
    var status: Int32 = 0
    #expect(waitpid(pid, &status, 0) == pid)
    #expect(kill(pid, 0) == -1)
  }
  @Test func missingHelperFailsWithoutDescriptors() {
    var fd: Int32 = -1
    var life: Int32 = -1
    var pid: pid_t = 0
    #expect(
      specter_start("/nonexistent/specter-helper", "/bin/sh", "/tmp", "", 24, 80, &fd, &life, &pid)
        == ENOENT)
    #expect(fd == -1 && life == -1)
  }
  @Test func oneHundredSessionCycles() throws {
    let path = try helper()
    for _ in 0..<100 {
      var fd: Int32 = -1
      var life: Int32 = -1
      var pid: pid_t = 0
      let result = specter_start(path, "/bin/sh", "/tmp", "", 24, 80, &fd, &life, &pid)
      #expect(result == 0)
      guard result == 0 else { return }
      close(fd)
      close(life)
      var status: Int32 = 0
      #expect(waitpid(pid, &status, 0) == pid)
    }
  }

}
