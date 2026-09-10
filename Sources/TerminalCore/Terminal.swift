import Foundation

/// Mutate only from the owning session queue. Snapshots are immutable values.
public final class Terminal {
  public private(set) var columns: Int
  public private(set) var rows: Int
  public private(set) var screen: [ScreenLine] = []
  public var history: [ScreenLine] {
    (0..<historyCount).compactMap { historyStorage[(historyStart + $0) % max(1, scrollbackLimit)] }
  }
  private var historyStorage: [ScreenLine?]
  private var historyStart = 0
  private var historyCount = 0
  public private(set) var cursor = Position(row: 0, column: 0)
  public private(set) var modes = TerminalModes()
  public private(set) var alternate = false
  public private(set) var generation: UInt64 = 0
  public private(set) var title = "Specter"
  public private(set) var effects: [TerminalEffect] = []
  public let scrollbackLimit: Int
  private var historyBytes = 0
  private var nextID: UInt64 = 0
  private var attributes = Attributes()
  private var savedCursor = Position(row: 0, column: 0)
  private var savedAttributes = Attributes()
  private var primaryScreen: [ScreenLine] = []
  private var primaryCursor = Position(row: 0, column: 0)
  private var scrollTop = 0
  private var scrollBottom: Int
  private var wrapPending = false
  private var tabs: Set<Int> = []
  // Ground, escape, CSI, OSC, OSC-escape, ignore, ignore-escape, charset.
  private var parserState = 0
  private var sequence: [UInt8] = []
  private var sequenceOverflow = false
  private var utf8: [UInt8] = []
  private var utf8Expected = 0
  private var lastPrinted: Position?
  private var lastCharacter = " "
  private var charsets = [false, false]
  private var activeCharset = 0
  private var charsetTarget = 0
  private var lineDrawing: Bool { charsets[activeCharset] }

  public init(columns: Int = 80, rows: Int = 24, scrollbackLimit: Int = 10_000) {
    self.columns = max(1, min(1000, columns))
    self.rows = max(1, min(1000, rows))
    self.scrollbackLimit = max(0, min(100_000, scrollbackLimit))
    scrollBottom = self.rows - 1
    historyStorage = Array(repeating: nil, count: self.scrollbackLimit)
    for _ in 0..<self.rows { screen.append(newLine()) }
    tabs = Set(stride(from: 8, to: self.columns, by: 8))
  }
  private func newLine() -> ScreenLine {
    nextID &+= 1
    return ScreenLine(id: nextID, columns: columns)
  }
  public func snapshot() -> ScreenSnapshot {
    ScreenSnapshot(
      columns: columns, rows: rows, lines: (alternate ? [] : history) + screen, cursor: cursor,
      modes: modes, alternate: alternate, generation: generation, title: title)
  }
  public func takeEffects() -> [TerminalEffect] {
    let result = effects
    effects.removeAll(keepingCapacity: true)
    return result
  }
  public func feed(_ data: some Sequence<UInt8>) {
    for byte in data { consume(byte) }
    generation &+= 1
  }
  public func finish() {
    if !utf8.isEmpty {
      put("�")
      utf8.removeAll()
      utf8Expected = 0
    }
    generation &+= 1
  }
  private func consume(_ b: UInt8) {
    switch parserState {
    case 1:
      parserState = 0
      switch b {
      case 91:
        parserState = 2
        sequence.removeAll(keepingCapacity: true)
        sequenceOverflow = false
      case 93:
        parserState = 3
        sequence.removeAll(keepingCapacity: true)
        sequenceOverflow = false
      case 80, 94, 95: parserState = 5
      case 40, 41:
        parserState = 7
        charsetTarget = Int(b - 40)
      case 55: saveCursor()
      case 56: restoreCursor()
      case 68: lineFeed()
      case 69:
        cursor.column = 0
        lineFeed()
      case 77:
        if cursor.row == scrollTop { scrollDown(1) } else { cursor.row = max(0, cursor.row - 1) }
      case 72: tabs.insert(cursor.column)
      case 99: reset()
      case 61: modes.applicationKeypad = true
      case 62: modes.applicationKeypad = false
      default: break
      }
    case 2:
      if b == 27 {
        parserState = 1
        return
      }
      if b == 24 || b == 26 {
        parserState = 0
        return
      }
      if b < 32 {
        control(b)
        return
      }
      if (0x40...0x7E).contains(b) {
        if !sequenceOverflow { csi(b) }
        parserState = 0
      } else if sequence.count < 256 {
        sequence.append(b)
      } else {
        sequenceOverflow = true
      }
    case 3:
      if b == 7 {
        osc()
        parserState = 0
      } else if b == 27 {
        parserState = 4
      } else if b == 24 || b == 26 {
        parserState = 0
      } else if sequence.count < 8192 {
        sequence.append(b)
      } else {
        sequenceOverflow = true
      }
    case 4:
      if b == 92 {
        osc()
        parserState = 0
      } else {
        parserState = 3
        sequenceOverflow = true
      }
    case 5: if b == 27 { parserState = 6 } else if b == 24 || b == 26 { parserState = 0 }
    case 6: parserState = b == 92 ? 0 : 5
    case 7:
      charsets[charsetTarget] = b == 48
      parserState = 0
    default:
      if b == 27 || b < 32 || b == 127 {
        if !utf8.isEmpty {
          put("�")
          utf8.removeAll()
          utf8Expected = 0
        }
        lastPrinted = nil
        if b == 27 { parserState = 1 } else { control(b) }
        return
      }
      if !utf8.isEmpty {
        if (0x80...0xBF).contains(b) {
          utf8.append(b)
          if utf8.count == utf8Expected {
            put(String(bytes: utf8, encoding: .utf8) ?? "�")
            utf8.removeAll()
            utf8Expected = 0
          }
          return
        }
        put("�")
        utf8.removeAll()
        utf8Expected = 0
      }
      if b < 128 {
        let map: [UInt8: String] = [
          106: "┘", 107: "┐", 108: "┌", 109: "└", 110: "┼", 113: "─", 116: "├", 117: "┤", 118: "┴",
          119: "┬", 120: "│",
        ]
        put(lineDrawing ? map[b] ?? String(UnicodeScalar(b)) : String(UnicodeScalar(b)))
      } else if (0xC2...0xF4).contains(b) {
        utf8 = [b]
        utf8Expected = b < 0xE0 ? 2 : b < 0xF0 ? 3 : 4
      } else {
        put("�")
      }
    }
  }
  private func control(_ b: UInt8) {
    switch b {
    case 7: if effects.count < 1024 { effects.append(.bell) }
    case 8:
      cursor.column = max(0, cursor.column - 1)
      wrapPending = false
    case 9:
      cursor.column = tabs.filter { $0 > cursor.column }.min() ?? (columns - 1)
      wrapPending = false
    case 10, 11, 12: lineFeed()
    case 13:
      cursor.column = 0
      wrapPending = false
    case 14: activeCharset = 1
    case 15: activeCharset = 0
    default: break
    }
  }
  public static func width(of text: String) -> Int { UnicodeWidth.width(text) }
  private func put(_ text: String) {
    if let p = lastPrinted, p.row < rows, p.column < columns {
      let old = screen[p.row].cells[p.column]
      let joined = old.text + text
      if UnicodeWidth.joins(old.text, text) && joined.utf8.count <= 1024 {
        let width = min(columns, Self.width(of: joined))
        if width == 2 && old.width == 1 && p.column + 1 == columns && modes.autoWrap {
          screen[p.row].cells[p.column] = Cell()
          screen[p.row].wrapped = true
          cursor.column = 0
          lineFeed()
          lastPrinted = nil
          put(joined)
          return
        }
        screen[p.row].cells[p.column].text = joined
        if width == 2 && old.width == 1 && p.column + 1 < columns {
          screen[p.row].cells[p.column].width = 2
          screen[p.row].cells[p.column + 1] = Cell("", width: 0, attributes: old.attributes)
          cursor.column = min(columns - 1, p.column + 2)
          wrapPending = p.column + 2 >= columns
        }
        return
      }
    }
    var text = text
    if text.unicodeScalars.first?.properties.generalCategory == .nonspacingMark {
      text = "◌" + text
    }
    let width = min(columns, Self.width(of: text))
    if wrapPending && modes.autoWrap || width == 2 && cursor.column == columns - 1 && modes.autoWrap
    {
      screen[cursor.row].wrapped = true
      cursor.column = 0
      lineFeed()
    }
    wrapPending = false
    if modes.insert {
      for _ in 0..<width {
        screen[cursor.row].cells.insert(Cell(attributes: attributes), at: cursor.column)
        screen[cursor.row].cells.removeLast()
      }
    }
    clearWide(row: cursor.row, column: cursor.column)
    screen[cursor.row].cells[cursor.column] = Cell(text, width: width, attributes: attributes)
    if width == 2 && cursor.column + 1 < columns {
      clearWide(row: cursor.row, column: cursor.column + 1)
      screen[cursor.row].cells[cursor.column + 1] = Cell("", width: 0, attributes: attributes)
    }
    lastPrinted = cursor
    lastCharacter = text
    if cursor.column + width >= columns {
      cursor.column = columns - 1
      wrapPending = true
    } else {
      cursor.column += width
    }
  }
  private func clearWide(row: Int, column: Int) {
    if screen[row].cells[column].width == 0 && column > 0 {
      screen[row].cells[column - 1] = Cell(attributes: attributes)
    }
    if screen[row].cells[column].width == 2 && column + 1 < columns {
      screen[row].cells[column + 1] = Cell(attributes: attributes)
    }
  }
  private func lineCost(_ line: ScreenLine) -> Int {
    line.cells.count * 96
      + line.cells.reduce(0) {
        $0 + $1.text.utf8.count + ($1.attributes.hyperlink?.utf8.count ?? 0)
      }
  }
  private func clearHistory() {
    historyStorage = Array(repeating: nil, count: scrollbackLimit)
    historyStart = 0
    historyCount = 0
    historyBytes = 0
  }
  private func appendHistory(_ line: ScreenLine) {
    guard scrollbackLimit > 0 else { return }
    let cost = lineCost(line)
    while historyCount > 0
      && (historyCount >= scrollbackLimit || historyBytes + cost > 64 * 1024 * 1024)
    {
      if let dropped = historyStorage[historyStart] { historyBytes -= lineCost(dropped) }
      historyStorage[historyStart] = nil
      historyStart = (historyStart + 1) % scrollbackLimit
      historyCount -= 1
    }
    guard cost <= 64 * 1024 * 1024 else { return }
    historyStorage[(historyStart + historyCount) % scrollbackLimit] = line
    historyCount += 1
    historyBytes += cost
  }
  private func lineFeed() {
    lastPrinted = nil
    wrapPending = false
    if cursor.row == scrollBottom {
      scrollUp(1)
    } else {
      cursor.row = min(rows - 1, cursor.row + 1)
    }
  }
  private func scrollUp(_ n: Int) {
    for _ in 0..<min(n, scrollBottom - scrollTop + 1) {
      let line = screen.remove(at: scrollTop)
      if !alternate && scrollTop == 0 && scrollBottom == rows - 1 { appendHistory(line) }
      screen.insert(newLine(), at: scrollBottom)
    }
  }
  private func scrollDown(_ n: Int) {
    for _ in 0..<min(n, scrollBottom - scrollTop + 1) {
      screen.remove(at: scrollBottom)
      screen.insert(newLine(), at: scrollTop)
    }
  }
  private func saveCursor() {
    savedCursor = cursor
    savedAttributes = attributes
  }
  private func restoreCursor() {
    cursor = savedCursor
    attributes = savedAttributes
    clampCursor()
    wrapPending = false
  }
  private func clampCursor() {
    cursor.row = max(0, min(rows - 1, cursor.row))
    cursor.column = max(0, min(columns - 1, cursor.column))
  }
  private func erase(row: Int, from: Int, to: Int) {
    guard from <= to else { return }
    for c in max(0, from)...min(columns - 1, to) {
      clearWide(row: row, column: c)
      screen[row].cells[c] = Cell(attributes: attributes)
    }
    screen[row].wrapped = false
  }
  private func csi(_ final: UInt8) {
    let pendingBefore = wrapPending
    lastPrinted = nil
    let raw = String(decoding: sequence, as: UTF8.self)
    let priv = raw.hasPrefix("?")
    let body = raw.trimmingCharacters(in: CharacterSet(charactersIn: "?><! "))
    let parts = body.split(separator: ";", omittingEmptySubsequences: false)
    guard parts.count <= 32 else { return }
    let values = parts.map { min(1_000_000, Int($0) ?? 0) }
    func value(_ i: Int = 0, _ fallback: Int = 1) -> Int {
      i < values.count && values[i] > 0 ? values[i] : fallback
    }
    let n = value()
    let first = values.first ?? 0
    switch final {
    case 65: cursor.row = max(modes.origin ? scrollTop : 0, cursor.row - n)
    case 66, 101: cursor.row = min(modes.origin ? scrollBottom : rows - 1, cursor.row + n)
    case 67, 97: cursor.column = min(columns - 1, cursor.column + n)
    case 68: cursor.column = max(0, cursor.column - n)
    case 69:
      cursor.row = min(rows - 1, cursor.row + n)
      cursor.column = 0
    case 70:
      cursor.row = max(0, cursor.row - n)
      cursor.column = 0
    case 71, 96: cursor.column = min(columns - 1, n - 1)
    case 72, 102:
      cursor.row = min(
        modes.origin ? scrollBottom : rows - 1, n - 1 + (modes.origin ? scrollTop : 0))
      cursor.column = min(columns - 1, value(1) - 1)
    case 100:
      cursor.row = min(
        modes.origin ? scrollBottom : rows - 1, n - 1 + (modes.origin ? scrollTop : 0))
    case 74:
      if first == 2 {
        for r in 0..<rows { erase(row: r, from: 0, to: columns - 1) }
      } else if first == 3 {
        clearHistory()
      } else if first == 0 {
        erase(row: cursor.row, from: cursor.column, to: columns - 1)
        if cursor.row + 1 < rows {
          for r in (cursor.row + 1)..<rows { erase(row: r, from: 0, to: columns - 1) }
        }
      } else if first == 1 {
        for r in 0..<cursor.row { erase(row: r, from: 0, to: columns - 1) }
        erase(row: cursor.row, from: 0, to: cursor.column)
      }
    case 75:
      erase(
        row: cursor.row, from: first == 0 ? cursor.column : 0,
        to: first == 1 ? cursor.column : columns - 1)
    case 88:
      erase(row: cursor.row, from: cursor.column, to: min(columns - 1, cursor.column + n - 1))
    case 76, 77:
      if (scrollTop...scrollBottom).contains(cursor.row) {
        for _ in 0..<min(n, scrollBottom - cursor.row + 1) {
          if final == 76 {
            screen.remove(at: scrollBottom)
            screen.insert(newLine(), at: cursor.row)
          } else {
            screen.remove(at: cursor.row)
            screen.insert(newLine(), at: scrollBottom)
          }
        }
      }
    case 64, 80:
      for _ in 0..<min(n, columns - cursor.column) {
        if final == 64 {
          screen[cursor.row].cells.insert(Cell(attributes: attributes), at: cursor.column)
          screen[cursor.row].cells.removeLast()
        } else {
          screen[cursor.row].cells.remove(at: cursor.column)
          screen[cursor.row].cells.append(Cell(attributes: attributes))
        }
      }
      repairLine(cursor.row)
    case 83: scrollUp(n)
    case 84: scrollDown(n)
    case 98: for _ in 0..<min(n, 10_000) { put(lastCharacter) }
    case 109: sgr(values)
    case 114:
      let top = value() - 1
      let bottom = value(1, rows) - 1
      if top >= 0 && bottom < rows && top < bottom {
        scrollTop = top
        scrollBottom = bottom
        cursor = Position(row: modes.origin ? top : 0, column: 0)
      }
    case 115: saveCursor()
    case 117: restoreCursor()
    case 103: if first == 3 { tabs.removeAll() } else if first == 0 { tabs.remove(cursor.column) }
    case 104, 108:
      for v in values { setMode(v, enabled: final == 104, privateMode: priv) }
    case 110:
      if first == 5 { reply("\u{1B}[0n") }
      if first == 6 { reply("\u{1B}[\(priv ? "?" : "")\(cursor.row + 1);\(cursor.column + 1)R") }
    case 99: reply(raw.hasPrefix(">") ? "\u{1B}[>0;1;0c" : "\u{1B}[?1;2c")
    default: break
    }
    wrapPending = [109, 110, 99, 115].contains(final) ? pendingBefore : false
    clampCursor()
  }
  private func reply(_ text: String) {
    if effects.count < 1024 { effects.append(.reply(Array(text.utf8))) }
  }
  private func sgr(_ values: [Int]) {
    var i = 0
    while i < values.count {
      let v = values[i]
      switch v {
      case 0:
        let link = attributes.hyperlink
        attributes = Attributes()
        attributes.hyperlink = link
      case 1: attributes.bold = true
      case 2: attributes.faint = true
      case 3: attributes.italic = true
      case 4, 21: attributes.underline = true
      case 7: attributes.inverse = true
      case 9: attributes.strike = true
      case 22:
        attributes.bold = false
        attributes.faint = false
      case 23: attributes.italic = false
      case 24: attributes.underline = false
      case 27: attributes.inverse = false
      case 29: attributes.strike = false
      case 30...37: attributes.foreground = .indexed(v - 30)
      case 40...47: attributes.background = .indexed(v - 40)
      case 90...97: attributes.foreground = .indexed(v - 90 + 8)
      case 100...107: attributes.background = .indexed(v - 100 + 8)
      case 39: attributes.foreground = .foreground
      case 49: attributes.background = .background
      case 38, 48:
        var color: TerminalColor?
        if i + 2 < values.count && values[i + 1] == 5 {
          color = .indexed(min(255, values[i + 2]))
          i += 2
        } else if i + 4 < values.count && values[i + 1] == 2 {
          color = .rgb(
            UInt8(clamping: values[i + 2]), UInt8(clamping: values[i + 3]),
            UInt8(clamping: values[i + 4]))
          i += 4
        }
        if let color {
          if v == 38 { attributes.foreground = color } else { attributes.background = color }
        }
      default: break
      }
      i += 1
    }
  }
  private func setMode(_ mode: Int, enabled: Bool, privateMode: Bool) {
    if !privateMode {
      if mode == 4 { modes.insert = enabled }
      return
    }
    switch mode {
    case 1: modes.applicationCursor = enabled
    case 6:
      modes.origin = enabled
      cursor = Position(row: enabled ? scrollTop : 0, column: 0)
    case 7: modes.autoWrap = enabled
    case 25: modes.cursorVisible = enabled
    case 47, 1047, 1049:
      guard alternate != enabled else { return }
      if enabled {
        primaryScreen = screen
        primaryCursor = cursor
        screen = (0..<rows).map { _ in newLine() }
        cursor = Position(row: 0, column: 0)
      } else {
        screen = primaryScreen
        cursor = primaryCursor
        primaryScreen.removeAll()
        normalizeScreen()
      }
      alternate = enabled
      scrollTop = 0
      scrollBottom = rows - 1
    case 1048: if enabled { saveCursor() } else { restoreCursor() }
    case 1000, 1002, 1003: modes.mouseMode = enabled ? mode : 0
    case 1004: modes.focusReporting = enabled
    case 1006: modes.sgrMouse = enabled
    case 2004: modes.bracketedPaste = enabled
    default: break
    }
  }
  private func osc() {
    guard !sequenceOverflow, let value = String(bytes: sequence, encoding: .utf8),
      let separator = value.firstIndex(of: ";")
    else { return }
    let code = value[..<separator]
    let payload = String(value[value.index(after: separator)...])
    if code == "0" || code == "2" { title = InputEncoder.safeTitle(payload) }
    if code == "8", let split = payload.firstIndex(of: ";") {
      let target = String(payload[payload.index(after: split)...])
      attributes.hyperlink = InputEncoder.safeURL(target)?.absoluteString
    }
  }
  private func repairLine(_ row: Int) {
    for c in 0..<columns {
      let w = screen[row].cells[c].width
      if w == 0 && (c == 0 || screen[row].cells[c - 1].width != 2) { screen[row].cells[c] = Cell() }
      if w == 2 && (c + 1 == columns || screen[row].cells[c + 1].width != 0) {
        screen[row].cells[c] = Cell()
      }
    }
  }
  private func normalizeScreen() {
    for r in screen.indices {
      if screen[r].cells.count > columns {
        screen[r].cells = Array(screen[r].cells.prefix(columns))
      } else {
        screen[r].cells += Array(repeating: Cell(), count: columns - screen[r].cells.count)
      }
    }
    while screen.count > rows {
      let line = screen.removeFirst()
      if !alternate { appendHistory(line) }
      cursor.row -= 1
    }
    while screen.count < rows { screen.append(newLine()) }
    for r in 0..<rows { repairLine(r) }
    clampCursor()
  }
  public func resize(columns: Int, rows: Int) {
    let cols = max(1, min(1000, columns))
    let height = max(1, min(1000, rows))
    guard cols != self.columns || height != self.rows else { return }
    let oldColumns = self.columns
    self.columns = cols
    if alternate {
      self.rows = height
      normalizeScreen()
    } else if cols != oldColumns {
      reflow(height: height)
    } else {
      self.rows = height
      if screen.count < height && historyCount > 0 {
        let historyLines = history
        let recovered = min(height - screen.count, historyLines.count)
        clearHistory()
        for line in historyLines.dropLast(recovered) { appendHistory(line) }
        screen.insert(contentsOf: historyLines.suffix(recovered), at: 0)
        cursor.row += recovered
      }
      normalizeScreen()
    }
    scrollTop = 0
    scrollBottom = height - 1
    tabs = Set(stride(from: 8, to: cols, by: 8))
    lastPrinted = nil
    wrapPending = false
    generation &+= 1
  }
  private func reflow(height: Int) {
    let source = history + screen
    let oldCursorRow = historyCount + cursor.row
    var output: [ScreenLine] = []
    var current = newLine()
    var column = 0
    var cursorAbsolute = Position(row: 0, column: 0)
    func commit(wrapped: Bool) {
      current.wrapped = wrapped
      output.append(current)
      current = newLine()
      column = 0
    }
    for (row, line) in source.enumerated() {
      var length = line.cells.count
      if !line.wrapped {
        while length > 0 && line.cells[length - 1].text == " "
          && line.cells[length - 1].attributes == Attributes()
        { length -= 1 }
        if row == oldCursorRow { length = max(length, min(line.cells.count, cursor.column + 1)) }
      }
      for c in 0..<length {
        var cell = line.cells[c]
        guard cell.width > 0 else { continue }
        let width = min(columns, cell.width)
        if column + width > columns { commit(wrapped: true) }
        if row == oldCursorRow
          && (c == cursor.column || c + cell.width > cursor.column && c < cursor.column)
        {
          cursorAbsolute = Position(row: output.count, column: column)
        }
        cell.width = width
        current.cells[column] = cell
        if width == 2 {
          current.cells[column + 1] = Cell("", width: 0, attributes: cell.attributes)
        }
        column += width
      }
      if !line.wrapped { commit(wrapped: false) }
    }
    if column > 0 { commit(wrapped: false) }
    let start = max(0, min(cursorAbsolute.row, output.count - height))
    clearHistory()
    for line in output.prefix(start) { appendHistory(line) }
    screen = Array(output.dropFirst(start).prefix(height))
    rows = height
    cursor = Position(row: cursorAbsolute.row - start, column: cursorAbsolute.column)
    normalizeScreen()
  }
  public func reset() {
    modes = TerminalModes()
    attributes = Attributes()
    cursor = Position(row: 0, column: 0)
    savedCursor = cursor
    savedAttributes = attributes
    alternate = false
    primaryScreen.removeAll()
    screen = (0..<rows).map { _ in newLine() }
    scrollTop = 0
    scrollBottom = rows - 1
    wrapPending = false
    lastPrinted = nil
    charsets = [false, false]
    activeCharset = 0
    tabs = Set(stride(from: 8, to: columns, by: 8))
    generation &+= 1
  }
}
