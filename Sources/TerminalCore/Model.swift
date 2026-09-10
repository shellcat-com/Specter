import Foundation

public enum TerminalColor: Hashable, Sendable {
  case foreground, background
  case indexed(Int)
  case rgb(UInt8, UInt8, UInt8)
}

public struct Attributes: Hashable, Sendable {
  public var foreground: TerminalColor = .foreground
  public var background: TerminalColor = .background
  public var bold = false
  public var faint = false
  public var italic = false
  public var underline = false
  public var inverse = false
  public var strike = false
  public var hyperlink: String?
  public init() {}
}

public struct Cell: Equatable, Sendable {
  public var text: String
  public var width: Int
  public var attributes: Attributes
  public init(_ text: String = " ", width: Int = 1, attributes: Attributes = Attributes()) {
    self.text = text
    self.width = width
    self.attributes = attributes
  }
}

public struct ScreenLine: Equatable, Sendable {
  public var id: UInt64
  public var cells: [Cell]
  public var wrapped = false
  public var text: String { cells.filter { $0.width != 0 }.map(\.text).joined() }
  public init(id: UInt64, columns: Int) {
    self.id = id
    cells = Array(repeating: Cell(), count: columns)
  }
}

public struct Position: Equatable, Comparable, Sendable {
  public var row: Int
  public var column: Int
  public init(row: Int, column: Int) {
    self.row = row
    self.column = column
  }
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
  }
}

public struct TerminalModes: Equatable, Sendable {
  public var applicationCursor = false
  public var applicationKeypad = false
  public var bracketedPaste = false
  public var focusReporting = false
  public var mouseMode = 0
  public var sgrMouse = false
  public var cursorVisible = true
  public var autoWrap = true
  public var origin = false
  public var insert = false
  public init() {}
}

public struct ScreenSnapshot: Sendable {
  public let columns: Int
  public let rows: Int
  public let lines: [ScreenLine]
  public let cursor: Position
  public let modes: TerminalModes
  public let alternate: Bool
  public let generation: UInt64
  public let title: String
  public var historyCount: Int { max(0, lines.count - rows) }
  public func selectedText(from start: Position, to end: Position) -> String {
    let a = min(start, end)
    let b = max(start, end)
    guard a.row >= 0, b.row < lines.count else { return "" }
    var output = ""
    for row in a.row...b.row {
      let lo = row == a.row ? max(0, a.column) : 0
      let hi = min(lines[row].cells.count, row == b.row ? b.column + 1 : columns)
      if lo < hi {
        var text = lines[row].cells[lo..<hi].filter { $0.width != 0 }.map(\.text).joined()
        if hi == columns && !lines[row].wrapped {
          while text.last == " " { text.removeLast() }
        }
        output += text
      }
      if row < b.row && !lines[row].wrapped { output += "\n" }
    }
    return output
  }
  public func search(_ query: String) -> [Position] {
    guard !query.isEmpty else { return [] }
    var text = ""
    var positions: [Position] = []
    for (r, line) in lines.enumerated() {
      for (c, cell) in line.cells.enumerated() where cell.width > 0 {
        text += cell.text
        positions.append(
          contentsOf: repeatElement(Position(row: r, column: c), count: cell.text.utf16.count))
      }
      if !line.wrapped {
        text += "\n"
        positions.append(Position(row: r, column: columns - 1))
      }
    }
    let haystack = text as NSString
    var offset = 0
    var hits: [Position] = []
    while offset < haystack.length && hits.count < 10_000 {
      let range = haystack.range(
        of: query, options: [.caseInsensitive],
        range: NSRange(location: offset, length: haystack.length - offset))
      if range.location == NSNotFound { break }
      hits.append(positions[range.location])
      offset = range.location + max(1, range.length)
    }
    return hits
  }
}

public enum TerminalEffect: Sendable, Equatable {
  case reply([UInt8])
  case bell
}

public enum InputEncoder {
  public static func key(_ key: String, modes: TerminalModes, modifiers: Int = 1) -> [UInt8] {
    let cursor = ["up": "A", "down": "B", "right": "C", "left": "D", "home": "H", "end": "F"]
    if let suffix = cursor[key] {
      if modifiers > 1 { return Array("\u{1B}[1;\(modifiers)\(suffix)".utf8) }
      return Array("\u{1B}\(modes.applicationCursor ? "O" : "[")\(suffix)".utf8)
    }
    let codes = [
      "insert": "2", "delete": "3", "pageUp": "5", "pageDown": "6", "f5": "15", "f6": "17",
      "f7": "18", "f8": "19", "f9": "20", "f10": "21", "f11": "23", "f12": "24",
    ]
    if let code = codes[key] {
      return Array("\u{1B}[\(code)\(modifiers > 1 ? ";\(modifiers)" : "")~".utf8)
    }
    if let index = ["f1", "f2", "f3", "f4"].firstIndex(of: key) {
      return [27, 79, UInt8(80 + index)]
    }
    return []
  }
  public static func pasteNeedsConfirmation(_ text: String) -> Bool {
    text.unicodeScalars.contains { $0.value < 32 && $0.value != 9 || $0.value == 127 }
  }
  public static func paste(_ text: String, bracketed: Bool) -> [UInt8] {
    let clean = String(
      text.unicodeScalars.filter {
        $0.value >= 32 && $0.value != 127 || [9, 10, 13].contains($0.value)
      })
    let normalized = clean.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\n", with: "\r")
    return Array((bracketed ? "\u{1B}[200~" + normalized + "\u{1B}[201~" : normalized).utf8)
  }
  public static func safeURL(_ text: String) -> URL? {
    guard text.utf8.count <= 2048,
      !text.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }),
      let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
      url.host != nil, url.user == nil, url.password == nil
    else { return nil }
    return url
  }
  public static func safeTitle(_ text: String) -> String {
    String(
      String(
        text.unicodeScalars.filter {
          $0.value >= 32 && $0.value != 127 && !(0x202A...0x202E).contains($0.value)
            && !(0x2066...0x2069).contains($0.value)
        }
      ).prefix(200))
  }
}
