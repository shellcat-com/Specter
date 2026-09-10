import Darwin
import Foundation
import PTYBridge
import Testing

struct ConcurrentPTYTests {
  /// Keep twelve shells alive together, resize each, then check distinct real output.
  @Test func twelveIndependentLivePTYs() throws {
    let helper = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent(".build/debug/SpecterPTY").path
    var sessions: [(fd: Int32, life: Int32, pid: pid_t)] = []
    defer {
      for session in sessions {
        close(session.fd)
        close(session.life)
        var status: Int32 = 0
        while waitpid(session.pid, &status, 0) < 0 && errno == EINTR {}
      }
    }
    for _ in 0..<12 {
      var fd: Int32 = -1
      var life: Int32 = -1
      var pid: pid_t = 0
      let result = specter_start(helper, "/bin/sh", "/tmp", "", 24, 80, &fd, &life, &pid)
      try #require(result == 0)
      sessions.append((fd, life, pid))
    }
    #expect(sessions.count == 12)
    #expect(Set(sessions.map(\.pid)).count == 12)
    for (i, session) in sessions.enumerated() {
      #expect(kill(session.pid, 0) == 0)
      #expect(specter_resize(session.fd, Int32(30 + i), Int32(90 + i)) == 0)
      // The full marker never appears in the echoed command, only in executed output.
      let command = Array("printf '__SPECTER_%s_OK__\\n' '\(i)'; stty size\n".utf8)
      let sent = command.withUnsafeBytes { write(session.fd, $0.baseAddress, $0.count) }
      #expect(sent == command.count)
    }
    var outputs = Array(repeating: "", count: 12)
    var bytes = [UInt8](repeating: 0, count: 4096)
    let deadline = Date().addingTimeInterval(10)
    while Date() < deadline {
      var complete = true
      for (i, session) in sessions.enumerated() {
        if outputs[i].contains("__SPECTER_\(i)_OK__")
          && outputs[i].contains("\(30 + i) \(90 + i)")
        {
          continue
        }
        complete = false
        var descriptor = pollfd(fd: session.fd, events: Int16(POLLIN), revents: 0)
        if poll(&descriptor, 1, 20) > 0 {
          let n = read(session.fd, &bytes, bytes.count)
          if n > 0 { outputs[i] += String(decoding: bytes.prefix(n), as: UTF8.self) }
        }
      }
      if complete { break }
    }
    for i in sessions.indices {
      #expect(outputs[i].contains("__SPECTER_\(i)_OK__"))
      #expect(outputs[i].contains("\(30 + i) \(90 + i)"))
      for j in sessions.indices where j != i {
        #expect(!outputs[i].contains("__SPECTER_\(j)_OK__"))
      }
    }
  }
}
