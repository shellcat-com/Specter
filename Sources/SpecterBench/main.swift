import Foundation
import TerminalCore

let clock = ContinuousClock()
if CommandLine.arguments.contains("--fuzz") {
  let seconds = Double(CommandLine.arguments.last ?? "600") ?? 600
  let deadline = clock.now.advanced(by: .seconds(seconds))
  var seed: UInt64 = 0x53_5045_4354_4552
  func next() -> UInt8 {
    seed ^= seed << 13
    seed ^= seed >> 7
    seed ^= seed << 17
    return UInt8(truncatingIfNeeded: seed)
  }
  var iterations = 0
  while clock.now < deadline {
    let terminal = Terminal(
      columns: 1 + Int(next() % 120), rows: 1 + Int(next() % 40), scrollbackLimit: 100)
    for _ in 0..<8 {
      let bytes = (0..<Int(next()) + 1).map { _ in next() }
      terminal.feed(bytes)
      _ = terminal.takeEffects()
      if next() % 4 == 0 {
        terminal.resize(columns: 1 + Int(next() % 120), rows: 1 + Int(next() % 40))
      }
      precondition(terminal.screen.count == terminal.rows)
      precondition(terminal.screen.allSatisfy { $0.cells.count == terminal.columns })
    }
    terminal.finish()
    iterations += 1
  }
  print("seed=0x53504543544552 iterations=\(iterations) duration_seconds=\(seconds) crashes=0")
} else {
  let payload = Array(
    "\u{1B}[38;2;140;190;240mSpecter throughput fixture 0123456789\u{1B}[0m\r\n".utf8)
  let terminal = Terminal(columns: 120, rows: 40, scrollbackLimit: 10_000)
  let lines = CommandLine.arguments.contains("--million") ? 1_000_000 : 20_000
  let duration = clock.measure { for _ in 0..<lines { terminal.feed(payload) } }
  let elapsed = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
  let result: [String: Any] = [
    "workload": "SGR text, 120x40, bounded 10000-row scrollback", "lines": lines,
    "bytes": payload.count * lines, "seconds": elapsed,
    "MiB_per_second": Double(payload.count * lines) / elapsed / 1_048_576,
    "retained_rows": terminal.history.count,
  ]
  print(
    String(
      data: try JSONSerialization.data(
        withJSONObject: result, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
}
