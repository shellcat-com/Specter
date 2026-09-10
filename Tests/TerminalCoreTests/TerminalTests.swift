import Foundation
import Testing

@testable import TerminalCore

struct TerminalTests {
  @Test func plainTextAndDelayedWrap() {
    let t = Terminal(columns: 4, rows: 2)
    t.feed("abcd".utf8)
    #expect(t.cursor == Position(row: 0, column: 3))
    t.feed("e".utf8)
    #expect(t.screen[0].text == "abcd")
    #expect(t.screen[0].wrapped)
    #expect(t.screen[1].text == "e   ")
  }
  @Test(arguments: [
    "\u{1B}[2;3H!", "\u{1B}[31;1mred\u{1B}[0m", "é👩🏽‍💻中", "\u{1B}]2;Title\u{1B}\\text",
    "\u{1B}[?1049hFull\u{1B}[?1049l", "\u{1B}[2;4r\u{1B}[4;1H\n",
  ])
  func fragmented(_ fixture: String) {
    let bytes = Array(fixture.utf8)
    let whole = Terminal(columns: 20, rows: 5)
    whole.feed(bytes)
    for split in 0...bytes.count {
      let t = Terminal(columns: 20, rows: 5)
      t.feed(bytes.prefix(split))
      t.feed(bytes.dropFirst(split))
      #expect(t.screen == whole.screen)
      #expect(t.cursor == whole.cursor)
      #expect(t.modes == whole.modes)
      #expect(t.title == whole.title)
    }
  }
  @Test func malformedUTF8Recovers() {
    let t = Terminal(columns: 20, rows: 2)
    t.feed([0xC0, 0xAF, 0xE2, 0x41, 0xF4, 0x90, 0x80, 0x80, 0x42, 0xC2])
    t.finish()
    #expect(t.screen[0].text.hasPrefix("���A�B�"))
  }
  @Test func unicodeWidthsAndRoundTrip() {
    let t = Terminal(columns: 40, rows: 2)
    let fixture = "e\u{301}中🇳🇵👩🏽‍💻👨‍👩‍👧‍👦"
    for byte in fixture.utf8 { t.feed([byte]) }
    #expect(t.cursor.column == 9)
    #expect(t.screen[0].cells[0].text == "e\u{301}")
    #expect(
      t.snapshot().selectedText(from: Position(row: 0, column: 0), to: Position(row: 0, column: 39))
        == fixture)
  }
  @Test func alternateScreenPreservesPrimary() {
    let t = Terminal(columns: 10, rows: 3)
    t.feed("primary\u{1B}[?1049hother\u{1B}[?1049l".utf8)
    #expect(t.screen[0].text == "primary   ")
    #expect(!t.alternate)
    #expect(t.cursor.column == 7)
  }
  @Test func eraseCursorAndAttributes() {
    let t = Terminal(columns: 10, rows: 3)
    t.feed("abcdef\u{1B}[1;3H\u{1B}[K\u{1B}[38;2;1;2;3;48;5;42;1;3;4;7mZ".utf8)
    #expect(t.screen[0].text == "abZ       ")
    let a = t.screen[0].cells[2].attributes
    #expect(a.foreground == .rgb(1, 2, 3))
    #expect(a.background == .indexed(42))
    #expect(a.bold && a.italic && a.underline && a.inverse)
  }
  @Test func boundedScrollback() {
    let t = Terminal(columns: 12, rows: 3, scrollbackLimit: 5)
    for i in 0..<100 { t.feed("\(i)\r\n".utf8) }
    #expect(t.history.count == 5)
    #expect(t.history.first?.text.hasPrefix("93") == true)
    #expect(t.screen.count == 3)
  }
  @Test func scrollRegionDoesNotLeakToHistory() {
    let t = Terminal(columns: 5, rows: 4)
    t.feed("top\u{1B}[2;3r\u{1B}[3;1Hlast\n".utf8)
    #expect(t.screen[0].text == "top  ")
    #expect(t.screen[1].text == "last ")
    #expect(t.history.isEmpty)
  }
  @Test func modesAndReplies() {
    let t = Terminal(columns: 10, rows: 3)
    t.feed("\u{1B}[?2004h\u{1B}[?1006h\u{1B}[?1002h\u{1B}[?1h\u{1B}[2;3H\u{1B}[6n".utf8)
    #expect(t.modes.bracketedPaste && t.modes.sgrMouse && t.modes.applicationCursor)
    #expect(t.modes.mouseMode == 1002)
    #expect(t.takeEffects() == [.reply(Array("\u{1B}[2;3R".utf8))])
    #expect(InputEncoder.key("up", modes: t.modes) == [27, 79, 65])
  }
  @Test func maliciousControlsHaveNoExternalEffects() {
    let t = Terminal()
    t.feed(
      "\u{1B}]52;c;c2VjcmV0\u{7}\u{1B}]8;;javascript:alert(1)\u{7}X\u{1B}]2;hello\u{202E}evil\u{7}"
        .utf8)
    #expect(t.takeEffects().isEmpty)
    #expect(t.screen[0].cells[0].attributes.hyperlink == nil)
    #expect(t.title == "helloevil")
    t.feed(Array("\u{1B}]2;".utf8) + Array(repeating: 65, count: 100_000) + [7, 66])
    #expect(t.title == "helloevil")
    #expect(t.screen[0].text.hasPrefix("XB"))
  }
  @Test func safePasteCannotCloseBracket() {
    let result = InputEncoder.paste("one\u{1B}[201~\ntwo", bracketed: true)
    #expect(result.filter { $0 == 27 }.count == 2)
    #expect(InputEncoder.pasteNeedsConfirmation("one\ntwo"))
    #expect(!InputEncoder.pasteNeedsConfirmation("one two"))
    #expect(InputEncoder.safeURL("file:///etc/passwd") == nil)
    #expect(InputEncoder.safeURL("https://example.com") != nil)
  }
  @Test func selectionAndSearchAcrossWrap() {
    let t = Terminal(columns: 4, rows: 3)
    t.feed("abcdefgh".utf8)
    let s = t.snapshot()
    #expect(
      s.selectedText(from: Position(row: 0, column: 0), to: Position(row: 1, column: 3))
        == "abcdefgh")
    #expect(s.search("def") == [Position(row: 0, column: 3)])
  }
  @Test func resizeNeverSplitsWideCell() {
    let t = Terminal(columns: 8, rows: 4)
    t.feed("abc中def\r\nline".utf8)
    for columns in [1, 4, 5, 120, 80] {
      t.resize(columns: columns, rows: 3)
      #expect(t.screen.count == 3)
      #expect(t.screen.allSatisfy { $0.cells.count == columns })
      for line in t.screen {
        for c in line.cells.indices where line.cells[c].width == 0 {
          #expect(c > 0 && line.cells[c - 1].width == 2)
        }
      }
    }
  }
  @Test func insertDeleteAndLineDrawing() {
    let t = Terminal(columns: 8, rows: 2)
    t.feed("abcd\u{1B}[1;2H\u{1B}[2@X\u{1B}[P\u{1B}(0q\u{1B}(B".utf8)
    #expect(t.screen[0].text.hasPrefix("aX─cd"))
  }
  @Test func designatingG1DoesNotActivateLineDrawing() {
    let t = Terminal(columns: 20, rows: 2)
    t.feed("\u{1B}(B\u{1B})0total\u{E}q\u{F}normal".utf8)
    #expect(t.screen[0].text.hasPrefix("total─normal"))
  }

  @Test func colorChangePreservesDelayedWrap() {
    let t = Terminal(columns: 4, rows: 2)
    t.feed("abcd\u{1B}[31mE".utf8)
    #expect(t.screen[0].text == "abcd")
    #expect(t.screen[1].cells[0].text == "E")
    #expect(t.screen[1].cells[0].attributes.foreground == .indexed(1))
  }

}
