import Foundation
import Testing

@testable import TerminalCore

struct UnicodeTests {
  @Test func unicode17OfficialGraphemeBoundaries() throws {
    let url = try #require(
      Bundle.module.url(
        forResource: "GraphemeBreakTest", withExtension: "txt", subdirectory: "Fixtures"))
    let text = try String(contentsOf: url, encoding: .utf8)
    var cases = 0
    for line in text.split(separator: "\n") {
      let body = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
      let tokens = body.split(separator: " ").map(String.init).filter { !$0.isEmpty }
      guard tokens.count >= 3 else { continue }
      var cluster = ""
      var boundary = "÷"
      for token in tokens {
        if token == "÷" || token == "×" {
          boundary = token
          continue
        }
        guard let value = UInt32(token, radix: 16), let scalar = UnicodeScalar(value) else {
          continue
        }
        let next = String(scalar)
        if !cluster.isEmpty {
          #expect(
            UnicodeWidth.joins(cluster, next) == (boundary == "×"), "Unicode boundary case: \(body)"
          )
        }
        if boundary == "÷" { cluster = next } else { cluster += next }
      }
      cases += 1
    }
    #expect(cases > 500)
  }
  @Test func reflowRetainsSoftWrappedTextAndCursor() {
    let t = Terminal(columns: 8, rows: 3)
    t.feed("abcdefghijkl".utf8)
    t.resize(columns: 4, rows: 4)
    let s = t.snapshot()
    #expect(s.lines[0].text == "abcd")
    #expect(s.lines[1].text == "efgh")
    #expect(s.lines[2].text == "ijkl")
    #expect(s.historyCount + s.cursor.row == 3)
    #expect(s.cursor.column == 0)
    #expect(
      s.selectedText(from: Position(row: 0, column: 0), to: Position(row: 2, column: 3))
        == "abcdefghijkl")
    t.resize(columns: 12, rows: 4)
    #expect(t.screen[0].text == "abcdefghijkl")
  }
  @Test func variationSelectorAtRightMarginMovesWholeCluster() {
    let t = Terminal(columns: 4, rows: 2)
    t.feed("abc❤".utf8)
    t.feed("️".utf8)
    #expect(t.screen[1].cells[0].text == "❤️")
    #expect(t.screen[1].cells[0].width == 2)
    #expect(t.screen[1].cells[1].width == 0)
  }
}
