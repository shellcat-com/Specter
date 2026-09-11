import AppKit
import Carbon
import MetalKit
import MetalTerminal
import PTYSession
import TerminalCore

@MainActor
public final class TerminalView: NSView, @preconcurrency NSTextInputClient {
  public private(set) var session: Session?
  public private(set) var screen: ScreenSnapshot?
  public private(set) var sessionState: SessionState = .idle
  public var onTitle: ((String) -> Void)?
  public var onState: ((SessionState) -> Void)?
  public var onFocus: (() -> Void)?
  let companion: SessionCompanion
  public let profileID: UUID
  public private(set) var renderer: Renderer?
  private var metalView: MTKView?
  private var blinkTimer: Timer?
  private var selected: (Position, Position)?
  private var selectedFirstID: UInt64?
  private var marked = NSMutableAttributedString(string: "")
  private var markedSelection = NSRange(location: NSNotFound, length: 0)
  private let composition = NSTextField(labelWithString: "")
  private var secureRequested = false
  private var secureActive = false
  private var searchHits: [Position] = []
  private var searchIndex = 0
  private var query = ""
  private var lastGrid = CGSize.zero
  private var drawScheduled = false
  private var sessionEpoch = UUID()
  public override var isFlipped: Bool { true }
  public override var acceptsFirstResponder: Bool { true }
  public init(profile: Profile) {
    profileID = profile.id
    companion = SessionCompanion(profile: profile)
    super.init(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
    wantsLayer = true
    composition.isHidden = true
    composition.drawsBackground = true
    composition.backgroundColor = .controlBackgroundColor
    composition.textColor = .labelColor
    composition.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
    if let device = MTLCreateSystemDefaultDevice() {
      do {
        let renderer = try Renderer(
          device: device, fontName: profile.fontName, fontSize: profile.fontSize)
        self.renderer = renderer
        let view = MTKView(frame: bounds, device: device)
        view.delegate = renderer
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.autoResizeDrawable = false
        view.colorPixelFormat = .bgra8Unorm
        view.autoresizingMask = [.width, .height]
        addSubview(view)
        metalView = view
      } catch { showFailure("Metal renderer could not start: \(error.localizedDescription)") }
    } else {
      showFailure("Metal is unavailable on this Mac.")
    }
    addSubview(composition)
    setAccessibilityElement(true)
    setAccessibilityRole(.textArea)
    setAccessibilityLabel("Terminal")
    NotificationCenter.default.addObserver(
      self, selector: #selector(preferencesChanged), name: .specterPreferencesChanged, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(appResigned), name: NSApplication.didResignActiveNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(windowResigned), name: NSWindow.didResignKeyNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(appActivated), name: NSApplication.didBecomeActiveNotification,
      object: nil)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(preferencesChanged),
      name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
    apply(profile)
    blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        guard let self, self.window?.isVisible == true, self.window?.isKeyWindow == true,
          self.window?.firstResponder === self,
          !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        else { return }
        self.renderer?.cursorVisible.toggle()
        self.redraw()
      }
    }
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
  private func showFailure(_ text: String) {
    let label = NSTextField(wrappingLabelWithString: text)
    label.frame = bounds.insetBy(dx: 24, dy: 24)
    label.autoresizingMask = [.width, .height]
    addSubview(label)
  }
  public func start() {
    guard session == nil, renderer != nil else { return }
    let profile =
      Preferences.shared.profiles.first { $0.id == profileID } ?? Preferences.shared.active
    let config = SessionConfiguration(
      shell: profile.shell.isEmpty ? nil : profile.shell,
      directory: profile.directory.isEmpty
        ? nil : NSString(string: profile.directory).expandingTildeInPath,
      scrollback: profile.scrollback)
    sessionEpoch = UUID()
    let epoch = sessionEpoch
    lastGrid = .zero
    let mailbox = SnapshotMailbox()
    let session = Session(
      configuration: config,
      onSnapshot: { [weak self] snapshot in
        if mailbox.offer(snapshot) {
          DispatchQueue.main.async {
            if let newest = mailbox.take(), self?.sessionEpoch == epoch { self?.receive(newest) }
          }
        }
      },
      onState: { [weak self] state in
        DispatchQueue.main.async {
          guard self?.sessionEpoch == epoch else { return }
          self?.sessionState = state
          self?.onState?(state)
        }
      }, onBell: { DispatchQueue.main.async { BellNotifications.deliver() } })
    self.session = session
    resizeSession()
    session.start()
  }
  public func restart() {
    session?.stop()
    session = nil
    start()
  }
  public func close() {
    blinkTimer?.invalidate()
    blinkTimer = nil
    disableSecure()
    session?.stop()
  }
  private func receive(_ snapshot: ScreenSnapshot) {
    if let first = selectedFirstID, snapshot.lines.first?.id != first {
      selected = nil
      selectedFirstID = nil
    }
    let oldCount = screen?.historyCount ?? 0
    screen = snapshot
    renderer?.snapshot = snapshot
    if let renderer, renderer.scrollOffset > 0 {
      renderer.scrollOffset = min(
        snapshot.historyCount, renderer.scrollOffset + max(0, snapshot.historyCount - oldCount))
    }
    renderer?.selection = selected
    renderer?.cursorVisible = true
    onTitle?(snapshot.title)
    if !query.isEmpty { searchHits = snapshot.search(query) }
    redraw()
    NSAccessibility.post(element: self, notification: .valueChanged)
  }
  @objc private func preferencesChanged() {
    let profile =
      Preferences.shared.profiles.first { $0.id == profileID } ?? Preferences.shared.active
    apply(profile)
  }
  private func apply(_ profile: Profile) {
    renderer?.theme = Preferences.shared.theme(
      for: profile, dark: effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    if NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast, let renderer {
      renderer.theme.foreground = renderer.theme.isDark ? "#FFFFFF" : "#000000"
      renderer.theme.background = renderer.theme.isDark ? "#000000" : "#FFFFFF"
    }
    renderer?.cursorVisible = true
    renderer?.cursorStyle = profile.cursorStyle
    renderer?.ligatures = profile.ligatures
    renderer?.configure(
      fontName: profile.fontName, size: profile.fontSize, scale: window?.backingScaleFactor ?? 2)
    redraw()
    lastGrid = .zero
    resizeSession()
  }
  public override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    preferencesChanged()
  }
  public override func viewDidChangeBackingProperties() {
    super.viewDidChangeBackingProperties()
    preferencesChanged()
  }
  public override func layout() {
    super.layout()
    metalView?.frame = bounds
    metalView?.bounds = CGRect(origin: .zero, size: bounds.size)
    let scale = window?.backingScaleFactor ?? 2
    metalView?.drawableSize = CGSize(
      width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
    resizeSession()
    redraw()
  }
  private func resizeSession() {
    guard let renderer else { return }
    let grid = CGSize(
      width: max(1, floor((bounds.width - 24) / renderer.rasterizer.cellWidth)),
      height: max(1, floor((bounds.height - 20) / renderer.rasterizer.cellHeight)))
    guard grid != lastGrid || session == nil else { return }
    lastGrid = grid
    session?.resize(columns: Int(grid.width), rows: Int(grid.height))
  }
  public func redraw() {
    guard !drawScheduled else { return }
    drawScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(8)) { [weak self] in
      guard let self else { return }
      self.drawScheduled = false
      guard self.window?.isVisible == true else { return }
      self.metalView?.draw()
    }
  }
  public override func hitTest(_ point: NSPoint) -> NSView? {
    bounds.contains(convert(point, from: superview)) && !isHidden ? self : nil
  }
  public override func becomeFirstResponder() -> Bool {
    onFocus?()
    updateSecure()
    if screen?.modes.focusReporting == true { session?.send(Array("\u{1B}[I".utf8)) }
    return true
  }
  public override func resignFirstResponder() -> Bool {
    disableSecure()
    if screen?.modes.focusReporting == true { session?.send(Array("\u{1B}[O".utf8)) }
    return true
  }
  public override func keyDown(with event: NSEvent) {
    if event.modifierFlags.contains(.command) {
      super.keyDown(with: event)
      return
    }
    renderer?.scrollOffset = 0
    renderer?.cursorVisible = true
    renderer?.lastInputTimestamp = CACurrentMediaTime()
    let flags = event.modifierFlags
    let keyNames: [UInt16: String] = [
      123: "left", 124: "right", 125: "down", 126: "up", 115: "home", 119: "end", 116: "pageUp",
      121: "pageDown", 117: "delete", 114: "insert", 122: "f1", 120: "f2", 99: "f3", 118: "f4",
      96: "f5", 97: "f6", 98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
    ]
    if let key = keyNames[event.keyCode], !hasMarkedText() {
      let modifiers =
        1 + (flags.contains(.shift) ? 1 : 0) + (flags.contains(.option) ? 2 : 0)
        + (flags.contains(.control) ? 4 : 0)
      session?.send(
        InputEncoder.key(key, modes: screen?.modes ?? TerminalModes(), modifiers: modifiers))
      return
    }
    if flags.contains(.control),
      let scalar = event.charactersIgnoringModifiers?.unicodeScalars.first, scalar.value < 128
    {
      session?.send([UInt8(scalar.value) & 0x1F])
      return
    }
    if event.keyCode == 48 && flags.contains(.shift) {
      session?.send([27, 91, 90])
      return
    }
    interpretKeyEvents([event])
  }
  public func insertText(_ string: Any, replacementRange: NSRange) {
    let text = (string as? NSAttributedString)?.string ?? string as? String ?? ""
    unmarkText()
    renderer?.lastInputTimestamp = CACurrentMediaTime()
    session?.send(Array(text.utf8))
  }
  public override func doCommand(by selector: Selector) {
    let name = NSStringFromSelector(selector)
    let bytes: [String: [UInt8]] = [
      "insertNewline:": [13], "insertTab:": [9], "deleteBackward:": [127], "cancelOperation:": [27],
      "deleteForward:": [27, 91, 51, 126], "moveToBeginningOfLine:": [1], "moveToEndOfLine:": [5],
    ]
    if let value = bytes[name] { session?.send(value) }
  }
  public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
    marked = NSMutableAttributedString(
      attributedString: (string as? NSAttributedString)
        ?? NSAttributedString(string: string as? String ?? ""))
    markedSelection = selectedRange
    composition.stringValue = marked.string
    composition.isHidden = false
    let rect = cursorRect()
    composition.frame = CGRect(
      x: rect.minX, y: rect.minY,
      width: max(80, CGFloat(marked.length) * (renderer?.rasterizer.cellWidth ?? 8)),
      height: rect.height)
    redraw()
  }
  public func unmarkText() {
    marked = NSMutableAttributedString(string: "")
    markedSelection = NSRange(location: NSNotFound, length: 0)
    composition.isHidden = true
  }
  public func hasMarkedText() -> Bool { marked.length > 0 }
  public func markedRange() -> NSRange {
    hasMarkedText()
      ? NSRange(location: 0, length: marked.length) : NSRange(location: NSNotFound, length: 0)
  }
  public func selectedRange() -> NSRange { markedSelection }
  public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
    [.underlineStyle, .foregroundColor]
  }
  public func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?)
    -> NSAttributedString?
  {
    guard range.location != NSNotFound, range.location < marked.length else { return nil }
    let safe = NSIntersectionRange(range, NSRange(location: 0, length: marked.length))
    actualRange?.pointee = safe
    return marked.attributedSubstring(from: safe)
  }
  private func cursorRect() -> CGRect {
    let cw = renderer?.rasterizer.cellWidth ?? 8
    let ch = renderer?.rasterizer.cellHeight ?? 18
    return CGRect(
      x: 12 + CGFloat(screen?.cursor.column ?? 0) * cw,
      y: 10 + CGFloat(screen?.cursor.row ?? 0) * ch, width: cw, height: ch)
  }
  public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
    actualRange?.pointee = range
    return window?.convertToScreen(convert(cursorRect(), to: nil)) ?? .zero
  }
  public func characterIndex(for point: NSPoint) -> Int { 0 }
  private func position(at event: NSEvent) -> Position {
    let point = convert(event.locationInWindow, from: nil)
    let cw = renderer?.rasterizer.cellWidth ?? 8
    let ch = renderer?.rasterizer.cellHeight ?? 18
    let start = max(0, (screen?.historyCount ?? 0) - (renderer?.scrollOffset ?? 0))
    return Position(
      row: start + max(0, min((screen?.rows ?? 1) - 1, Int((point.y - 10) / ch))),
      column: max(0, min((screen?.columns ?? 1) - 1, Int((point.x - 12) / cw))))
  }
  public override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
    if reportMouse(event, release: false) { return }
    let p = position(at: event)
    if event.modifierFlags.contains(.command), let screen, p.row < screen.lines.count,
      let link = screen.lines[p.row].cells[p.column].attributes.hyperlink,
      let url = InputEncoder.safeURL(link)
    {
      let alert = NSAlert()
      alert.messageText = "Open link?"
      alert.informativeText = url.absoluteString
      alert.addButton(withTitle: "Open")
      alert.addButton(withTitle: "Cancel")
      if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(url) }
      return
    }
    selected = (p, p)
    selectedFirstID = screen?.lines.first?.id
    if event.clickCount == 3 {
      selected = (
        Position(row: p.row, column: 0), Position(row: p.row, column: (screen?.columns ?? 1) - 1)
      )
    } else if event.clickCount == 2, let line = screen?.lines[p.row] {
      var a = p.column
      var b = p.column
      while a > 0 && line.cells[a - 1].text != " " { a -= 1 }
      while b + 1 < line.cells.count && line.cells[b + 1].text != " " { b += 1 }
      selected = (Position(row: p.row, column: a), Position(row: p.row, column: b))
    }
    renderer?.selection = selected
    redraw()
  }
  public override func mouseDragged(with event: NSEvent) {
    if reportMouse(event, release: false, motion: true) { return }
    if let a = selected?.0 {
      selected = (a, position(at: event))
      renderer?.selection = selected
      redraw()
    }
  }
  public override func mouseUp(with event: NSEvent) { _ = reportMouse(event, release: true) }
  private func reportMouse(_ event: NSEvent, release: Bool, motion: Bool = false) -> Bool {
    guard let screen, screen.modes.mouseMode != 0, !event.modifierFlags.contains(.shift) else {
      return false
    }
    if motion && screen.modes.mouseMode == 1000 { return true }
    let p = position(at: event)
    let row = p.row - screen.historyCount + 1
    var button = release ? 3 : Int(event.buttonNumber)
    if motion { button += 32 }
    if event.modifierFlags.contains(.option) { button += 8 }
    if event.modifierFlags.contains(.control) { button += 16 }
    if screen.modes.sgrMouse {
      session?.send(
        Array(
          "\u{1B}[<\(release ? Int(event.buttonNumber) : button);\(p.column + 1);\(max(1, row))\(release ? "m" : "M")"
            .utf8))
    } else if p.column < 223 && row < 224 {
      session?.send([
        27, 91, 77, UInt8(clamping: button + 32), UInt8(clamping: p.column + 33),
        UInt8(clamping: row + 32),
      ])
    }
    return true
  }
  public override func scrollWheel(with event: NSEvent) {
    guard let renderer, let screen else { return }
    if screen.modes.mouseMode != 0 && !event.modifierFlags.contains(.shift) {
      let p = position(at: event)
      let button = event.scrollingDeltaY > 0 ? 64 : 65
      if screen.modes.sgrMouse {
        session?.send(
          Array(
            "\u{1B}[<\(button);\(p.column + 1);\(max(1, p.row - screen.historyCount + 1))M".utf8))
      }
      return
    }
    let amount = Int(event.scrollingDeltaY / (event.hasPreciseScrollingDeltas ? 3 : 1))
    renderer.scrollOffset = max(0, min(screen.historyCount, renderer.scrollOffset + amount))
    redraw()
  }
  @objc public func copy(_ sender: Any?) {
    guard let screen, let selected else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(
      screen.selectedText(from: selected.0, to: selected.1), forType: .string)
  }
  @objc public func paste(_ sender: Any?) {
    guard let text = NSPasteboard.general.string(forType: .string) else { return }
    if InputEncoder.pasteNeedsConfirmation(text) {
      let alert = NSAlert()
      alert.messageText = "Paste multiple lines or control characters?"
      alert.informativeText = "Line breaks can execute commands. Escape controls will be removed."
      alert.addButton(withTitle: "Paste")
      alert.addButton(withTitle: "Cancel")
      guard alert.runModal() == .alertFirstButtonReturn else { return }
    }
    session?.send(InputEncoder.paste(text, bracketed: screen?.modes.bracketedPaste ?? false))
  }
  @objc public override func selectAll(_ sender: Any?) {
    guard let screen else { return }
    selected = (
      Position(row: 0, column: 0), Position(row: screen.lines.count - 1, column: screen.columns - 1)
    )
    renderer?.selection = selected
    redraw()
  }
  public func search(_ text: String, direction: Int = 0) -> Int {
    if text != query {
      query = text
      searchHits = screen?.search(text) ?? []
      searchIndex = 0
    } else if !searchHits.isEmpty {
      searchIndex = (searchIndex + direction + searchHits.count) % searchHits.count
    }
    guard !searchHits.isEmpty else {
      renderer?.searchHit = nil
      redraw()
      return 0
    }
    searchIndex = min(searchIndex, searchHits.count - 1)
    let hit = searchHits[searchIndex]
    renderer?.searchHit = hit
    renderer?.scrollOffset = max(0, (screen?.historyCount ?? 0) - hit.row)
    redraw()
    return searchHits.count
  }
  public func toggleSecureInput() {
    secureRequested.toggle()
    updateSecure()
  }
  public var secureInputEnabled: Bool { secureRequested }
  @objc private func windowResigned(_ notification: Notification) {
    if notification.object as? NSWindow === window { disableSecure() }
  }
  @objc private func appResigned() { disableSecure() }
  @objc private func appActivated() { updateSecure() }
  private func updateSecure() {
    if secureRequested && NSApp.isActive && window?.firstResponder === self
      && window?.isKeyWindow == true
    {
      if !secureActive { secureActive = EnableSecureEventInput() == noErr }
    } else {
      disableSecure()
    }
  }
  private func disableSecure() {
    if secureActive {
      _ = DisableSecureEventInput()
      secureActive = false
    }
  }
  public override func accessibilityValue() -> Any? {
    screen?.lines.suffix(screen?.rows ?? 0).map(\.text).joined(separator: "\n") ?? ""
  }
  public override func accessibilitySelectedText() -> String? {
    guard let screen, let selected else { return nil }
    return screen.selectedText(from: selected.0, to: selected.1)
  }
  public override func accessibilityNumberOfCharacters() -> Int {
    (accessibilityValue() as? String)?.utf16.count ?? 0
  }
  public override func accessibilityVisibleCharacterRange() -> NSRange {
    NSRange(location: 0, length: accessibilityNumberOfCharacters())
  }
  public override func accessibilityString(for range: NSRange) -> String? {
    let text = (accessibilityValue() as? String ?? "") as NSString
    guard range.location != NSNotFound, range.location <= text.length,
      range.length <= text.length - range.location
    else { return nil }
    return text.substring(with: range)
  }
  public override func accessibilityLine(for index: Int) -> Int {
    let text = (accessibilityValue() as? String ?? "") as NSString
    guard index >= 0, index <= text.length else { return NSNotFound }
    return text.substring(to: index).filter { $0 == "\n" }.count
  }
  public override func accessibilityRange(forLine line: Int) -> NSRange {
    let lines = (accessibilityValue() as? String ?? "").components(separatedBy: "\n")
    guard line >= 0, line < lines.count else { return NSRange(location: NSNotFound, length: 0) }
    return NSRange(
      location: lines.prefix(line).reduce(0) { $0 + $1.utf16.count + 1 },
      length: lines[line].utf16.count)
  }
  public override func accessibilityRange(for index: Int) -> NSRange {
    guard index >= 0, index < accessibilityNumberOfCharacters() else {
      return NSRange(location: NSNotFound, length: 0)
    }
    return ((accessibilityValue() as? String ?? "") as NSString).rangeOfComposedCharacterSequence(
      at: index)
  }
  public override func accessibilityFrame(for range: NSRange) -> NSRect {
    let row = accessibilityLine(for: range.location)
    let lineRange = accessibilityRange(forLine: row)
    guard row != NSNotFound, lineRange.location != NSNotFound, let renderer else { return .zero }
    let prefix =
      accessibilityString(
        for: NSRange(
          location: lineRange.location, length: max(0, range.location - lineRange.location))) ?? ""
    let column = prefix.reduce(0) { $0 + Terminal.width(of: String($1)) }
    let selectedText = accessibilityString(for: range) ?? ""
    let width = max(1, selectedText.reduce(0) { $0 + Terminal.width(of: String($1)) })
    let rect = CGRect(
      x: 12 + CGFloat(column) * renderer.rasterizer.cellWidth,
      y: 10 + CGFloat(row) * renderer.rasterizer.cellHeight,
      width: CGFloat(width) * renderer.rasterizer.cellWidth, height: renderer.rasterizer.cellHeight)
    return window?.convertToScreen(convert(rect, to: nil)) ?? .zero
  }
  public override func accessibilityInsertionPointLineNumber() -> Int { screen?.cursor.row ?? 0 }
}
