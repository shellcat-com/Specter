import AppKit
import PTYSession
import Quartz
import SwiftUI

@MainActor
public final class WorkspaceController: NSWindowController, NSWindowDelegate, NSSearchFieldDelegate
{
  public private(set) var terminals: [TerminalView] = []
  public private(set) var activeTerminal: TerminalView?
  public var onClosed: (() -> Void)?
  public var onLayoutChanged: (() -> Void)?
  public var horizontalSplit: Bool {
    get { !split.isVertical }
    set { split.isVertical = !newValue }
  }
  private let split = NSSplitView()
  private let findBar = NSStackView()
  private let searchField = NSSearchField()
  private let matchCount = NSTextField(labelWithString: "")
  private let status = NSTextField(labelWithString: "Starting shell…")
  private let restartButton = NSButton(title: "Restart shell", target: nil, action: nil)
  public init(profile: Profile) {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 960, height: 640),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "Specter"
    window.minSize = NSSize(width: 360, height: 240)
    window.tabbingIdentifier = "SpecterTerminal"
    window.tabbingMode = .preferred
    window.isReleasedWhenClosed = false
    super.init(window: window)
    window.delegate = self
    let root = NSStackView()
    root.orientation = .vertical
    root.spacing = 0
    root.translatesAutoresizingMaskIntoConstraints = false
    window.contentView = NSView()
    window.contentView!.addSubview(root)
    NSLayoutConstraint.activate([
      root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
      root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
      root.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
      root.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),
    ])
    findBar.orientation = .horizontal
    findBar.spacing = 8
    findBar.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    searchField.placeholderString = "Find in scrollback"
    searchField.delegate = self
    searchField.sendsSearchStringImmediately = true
    searchField.setAccessibilityLabel("Find in scrollback")
    findBar.addArrangedSubview(searchField)
    findBar.addArrangedSubview(matchCount)
    findBar.addArrangedSubview(
      NSButton(title: "Previous", target: self, action: #selector(previousMatch)))
    findBar.addArrangedSubview(NSButton(title: "Next", target: self, action: #selector(nextMatch)))
    findBar.addArrangedSubview(NSButton(title: "Done", target: self, action: #selector(hideFind)))
    findBar.isHidden = true
    root.addArrangedSubview(findBar)
    split.isVertical = true
    split.dividerStyle = .thin
    root.addArrangedSubview(split)
    let bottom = NSStackView()
    bottom.orientation = .horizontal
    bottom.edgeInsets = NSEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
    status.font = .systemFont(ofSize: 11)
    status.textColor = .secondaryLabelColor
    status.setContentHuggingPriority(.defaultLow, for: .horizontal)
    bottom.addArrangedSubview(status)
    restartButton.target = self
    restartButton.action = #selector(restart)
    restartButton.isHidden = true
    bottom.addArrangedSubview(restartButton)
    root.addArrangedSubview(bottom)
    NSLayoutConstraint.activate([
      split.widthAnchor.constraint(equalTo: root.widthAnchor),
      findBar.widthAnchor.constraint(equalTo: root.widthAnchor),
      bottom.widthAnchor.constraint(equalTo: root.widthAnchor),
      bottom.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
    ])
    addPane(profile: profile)
    window.center()
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
  public func addPane(profile: Profile) {
    guard terminals.count < 8 else {
      NSSound.beep()
      return
    }
    let terminal = TerminalView(profile: profile)
    terminal.translatesAutoresizingMaskIntoConstraints = false
    terminal.onTitle = { [weak self, weak terminal] title in
      if self?.activeTerminal === terminal {
        self?.window?.title = title.isEmpty ? "Specter" : title
      }
    }
    terminal.onFocus = { [weak self, weak terminal] in
      self?.activeTerminal = terminal
      if let terminal { self?.updateState(terminal.sessionState) }
    }
    terminal.onState = { [weak self, weak terminal] state in
      if self?.activeTerminal === terminal { self?.updateState(state) }
    }
    terminals.append(terminal)
    split.addArrangedSubview(terminal)
    activeTerminal = terminal
    split.adjustSubviews()
    window?.makeFirstResponder(terminal)
    terminal.start()
  }
  public func splitPane(horizontal: Bool) {
    split.isVertical = !horizontal
    addPane(profile: Preferences.shared.active)
  }
  public func closePane() {
    guard terminals.count > 1, let activeTerminal else {
      window?.performClose(nil)
      return
    }
    activeTerminal.close()
    activeTerminal.removeFromSuperview()
    terminals.removeAll { $0 === activeTerminal }
    self.activeTerminal = terminals.last
    window?.makeFirstResponder(self.activeTerminal)
    split.adjustSubviews()
  }
  public func focusNextPane() {
    guard let activeTerminal, let i = terminals.firstIndex(where: { $0 === activeTerminal }) else {
      return
    }
    window?.makeFirstResponder(terminals[(i + 1) % terminals.count])
  }
  private func updateState(_ state: SessionState) {
    restartButton.isHidden = true
    switch state {
    case .idle, .starting: status.stringValue = "Starting shell…"
    case .running:
      status.stringValue =
        "\(Preferences.shared.profiles.first { $0.id == activeTerminal?.profileID }?.name ?? "Terminal")  ·  Shift-drag selects when mouse reporting is active"
    case .stopping: status.stringValue = "Closing session…"
    case .exited(let raw):
      status.stringValue =
        raw & 0x7F == 0
        ? "Shell exited with status \((raw >> 8) & 0xFF)" : "Shell ended by signal \(raw & 0x7F)"
      restartButton.isHidden = false
    case .failed(let message):
      status.stringValue = message
      restartButton.isHidden = false
    }
  }
  @objc private func restart() { activeTerminal?.restart() }
  public func showFind() {
    findBar.isHidden = false
    window?.makeFirstResponder(searchField)
  }
  @objc private func hideFind() {
    findBar.isHidden = true
    searchField.stringValue = ""
    _ = activeTerminal?.search("")
    window?.makeFirstResponder(activeTerminal)
  }
  public func controlTextDidChange(_ obj: Notification) {
    matchCount.stringValue = "\(activeTerminal?.search(searchField.stringValue) ?? 0) matches"
  }
  @objc public func nextMatch() {
    _ = activeTerminal?.search(searchField.stringValue, direction: 1)
  }
  @objc public func previousMatch() {
    _ = activeTerminal?.search(searchField.stringValue, direction: -1)
  }
  public func windowWillClose(_ notification: Notification) {
    for terminal in terminals { terminal.close() }
    onClosed?()
  }
  public func windowDidResize(_ notification: Notification) { onLayoutChanged?() }
  public func windowDidMove(_ notification: Notification) { onLayoutChanged?() }
  public func windowDidBecomeKey(_ notification: Notification) {
    window?.makeFirstResponder(activeTerminal)
  }
}

@MainActor
public final class SpecterApplication: NSObject, NSApplicationDelegate, NSMenuItemValidation,
  @preconcurrency QLPreviewPanelDataSource
{
  private var windows: [WorkspaceController] = []
  private var settingsController: NSWindowController?
  private var previewURL: NSURL?
  private var galleryController: NSWindowController?
  private var overviewController: NSWindowController?
  private weak var auxiliaryReturnWindow: NSWindow?
  private struct SavedWindow: Codable {
    let frame: String
    let profileIDs: [UUID]
    var horizontal: Bool?
    var tabGroup: String?
  }
  public override init() { super.init() }
  public func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    buildMenu()
    if Preferences.shared.restoreWindows,
      let data = UserDefaults.standard.data(forKey: "windowLayouts"),
      let saved = try? JSONDecoder().decode([SavedWindow].self, from: data), !saved.isEmpty
    {
      var restoredGroups: [String: NSWindow] = [:]
      for record in saved.prefix(12) {
        let profiles = record.profileIDs.compactMap { id in
          Preferences.shared.profiles.first { $0.id == id }
        }
        let controller = createWindow(profile: profiles.first ?? Preferences.shared.active)
        controller.window?.setFrame(NSRectFromString(record.frame), display: true)
        controller.horizontalSplit = record.horizontal ?? false
        if let group = record.tabGroup, let window = controller.window {
          if let existing = restoredGroups[group] {
            existing.addTabbedWindow(window, ordered: .above)
          } else {
            restoredGroups[group] = window
          }
        }
        for profile in profiles.dropFirst().prefix(7) { controller.addPane(profile: profile) }
      }
    } else {
      newWindow(nil)
    }
    NSApp.activate(ignoringOtherApps: true)
  }
  private func persistLayouts() {
    guard Preferences.shared.restoreWindows else {
      UserDefaults.standard.removeObject(forKey: "windowLayouts")
      return
    }
    var groups: [ObjectIdentifier: String] = [:]
    let saved = windows.compactMap { controller -> SavedWindow? in
      guard let window = controller.window else { return nil }
      let key = ObjectIdentifier(window.tabbedWindows?.first ?? window)
      let group = groups[key] ?? UUID().uuidString
      groups[key] = group
      return SavedWindow(
        frame: NSStringFromRect(window.frame), profileIDs: controller.terminals.map(\.profileID),
        horizontal: controller.horizontalSplit, tabGroup: group)
    }
    if let data = try? JSONEncoder().encode(saved) {
      UserDefaults.standard.set(data, forKey: "windowLayouts")
    }
  }
  public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    persistLayouts()
    for controller in windows { for terminal in controller.terminals { terminal.close() } }
    return .terminateNow
  }
  public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
  public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
    -> Bool
  {
    if !flag { newWindow(nil) }
    return true
  }
  private var current: WorkspaceController? { windows.first { $0.window === NSApp.keyWindow } }
  @discardableResult private func createWindow(profile: Profile) -> WorkspaceController {
    let controller = WorkspaceController(profile: profile)
    controller.onClosed = { [weak self, weak controller] in
      self?.windows.removeAll { $0 === controller }
    }
    controller.onLayoutChanged = { [weak self] in self?.persistLayouts() }
    windows.append(controller)
    controller.showWindow(nil)
    return controller
  }
  @objc private func newWindow(_ sender: Any?) { createWindow(profile: Preferences.shared.active) }
  @objc private func newTab(_ sender: Any?) {
    let existing = current?.window
    let controller = createWindow(profile: Preferences.shared.active)
    if let existing, let window = controller.window {
      existing.addTabbedWindow(window, ordered: .above)
      window.makeKeyAndOrderFront(nil)
    }
  }
  @objc private func splitVertical(_ sender: Any?) { current?.splitPane(horizontal: false) }
  @objc private func splitHorizontal(_ sender: Any?) { current?.splitPane(horizontal: true) }
  @objc private func closePane(_ sender: Any?) { current?.closePane() }
  @objc private func focusPane(_ sender: Any?) { current?.focusNextPane() }
  @objc private func find(_ sender: Any?) { current?.showFind() }
  @objc private func nextMatch(_ sender: Any?) { current?.nextMatch() }
  @objc private func secure(_ sender: Any?) { current?.activeTerminal?.toggleSecureInput() }
  @objc private func settings(_ sender: Any?) {
    if settingsController == nil {
      let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
      window.title = "Specter Settings"
      window.styleMask = [.titled, .closable]
      window.center()
      settingsController = NSWindowController(window: window)
    }
    settingsController?.showWindow(nil)
  }
  private func closeAuxiliary(_ controller: NSWindowController?) {
    controller?.close()
    (auxiliaryReturnWindow ?? windows.last?.window)?.makeKeyAndOrderFront(nil)
  }
  @objc private func themes(_ sender: Any?) {
    if let window = current?.window { auxiliaryReturnWindow = window }
    if galleryController == nil {
      let window = NSWindow(
        contentViewController: NSHostingController(
          rootView: ThemeGalleryView(onDone: { [weak self] in
            self?.closeAuxiliary(self?.galleryController)
          })))
      window.title = "Specter Themes"
      window.tabbingMode = .disallowed
      window.setContentSize(NSSize(width: 860, height: 650))
      window.styleMask = [.titled, .closable, .resizable]
      window.minSize = NSSize(width: 600, height: 450)
      window.center()
      galleryController = NSWindowController(window: window)
    }
    galleryController?.showWindow(nil)
  }
  @objc private func sessionOverview(_ sender: Any?) {
    if let window = current?.window { auxiliaryReturnWindow = window }
    let entries = windows.enumerated().flatMap { windowIndex, controller in
      controller.terminals.enumerated().map { paneIndex, terminal in
        let profile = Preferences.shared.profiles.first { $0.id == terminal.profileID }
        return SessionEntry(
          id: ObjectIdentifier(terminal),
          name: "Session \(windowIndex + 1).\(paneIndex + 1) · \(profile?.name ?? "Terminal")",
          detail: "\(controller.window?.title ?? "Specter") · Pane \(paneIndex + 1)",
          activate: { [weak self, weak controller, weak terminal] in
            self?.overviewController?.close()
            controller?.window?.makeKeyAndOrderFront(nil)
            controller?.window?.makeFirstResponder(terminal)
          })
      }
    }
    overviewController?.close()
    let window = NSWindow(
      contentViewController: NSHostingController(
        rootView: SessionOverview(
          entries: entries,
          onDone: { [weak self] in self?.closeAuxiliary(self?.overviewController) })))
    window.title = "Specter Sessions"
    window.tabbingMode = .disallowed
    window.styleMask = [.titled, .closable]
    window.center()
    overviewController = NSWindowController(window: window)
    overviewController?.showWindow(nil)
  }
  @objc private func showHandbook(_ sender: Any?) {
    guard let url = Bundle.main.url(forResource: "Handbook", withExtension: "html"),
      NSWorkspace.shared.open(url)
    else {
      let alert = NSAlert()
      alert.messageText = "The handbook could not be opened"
      alert.informativeText =
        "Build and open the complete Specter.app bundle to read the offline handbook."
      alert.runModal()
      return
    }
  }
  @objc private func exportPerformance(_ sender: Any?) {
    guard let report = current?.activeTerminal?.renderer?.performanceReport() else { return }
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "specter-performance.json"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        .write(to: url, options: .atomic)
    } catch { NSAlert(error: error).runModal() }
  }
  @objc private func quickLook(_ sender: Any?) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.message = "Choose a file to preview. Specter reads only the file you select."
    guard panel.runModal() == .OK, let url = panel.url, let preview = QLPreviewPanel.shared() else {
      return
    }
    previewURL = url as NSURL
    preview.dataSource = self
    preview.reloadData()
    preview.makeKeyAndOrderFront(nil)
  }
  public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { previewURL == nil ? 0 : 1 }
  public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (
    any QLPreviewItem
  )! { previewURL }
  public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(secure(_:)) {
      menuItem.state = current?.activeTerminal?.secureInputEnabled == true ? .on : .off
    }
    return true
  }
  private func buildMenu() {
    let main = NSMenu()
    func menu(_ name: String) -> NSMenu {
      let item = NSMenuItem()
      item.title = name
      let menu = NSMenu(title: name)
      item.submenu = menu
      main.addItem(item)
      return menu
    }
    func add(
      _ menu: NSMenu, _ title: String, _ action: Selector?, _ key: String = "",
      _ modifiers: NSEvent.ModifierFlags = .command, target: AnyObject? = nil
    ) {
      let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
      item.keyEquivalentModifierMask = modifiers
      item.target = target
      menu.addItem(item)
    }
    let app = menu("Specter")
    add(
      app, "About Specter", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), target: NSApp
    )
    add(app, "Settings…", #selector(settings(_:)), ",", target: self)
    add(app, "Theme Gallery…", #selector(themes(_:)), "t", [.command, .shift], target: self)
    add(app, "Secure Keyboard Entry", #selector(secure(_:)), target: self)
    app.addItem(.separator())
    add(app, "Hide Specter", #selector(NSApplication.hide(_:)), "h", target: NSApp)
    add(app, "Quit Specter", #selector(NSApplication.terminate(_:)), "q", target: NSApp)
    let file = menu("Shell")
    add(file, "New Window", #selector(newWindow(_:)), "n", target: self)
    add(file, "New Tab", #selector(newTab(_:)), "t", target: self)
    add(file, "Split Right", #selector(splitVertical(_:)), "d", target: self)
    add(file, "Split Below", #selector(splitHorizontal(_:)), "d", [.command, .shift], target: self)
    add(file, "Export Performance Report…", #selector(exportPerformance(_:)), target: self)
    add(file, "Quick Look File…", #selector(quickLook(_:)), target: self)
    add(file, "Close Pane", #selector(closePane(_:)), "w", target: self)
    let edit = menu("Edit")
    add(edit, "Copy", #selector(NSText.copy(_:)), "c")
    add(edit, "Paste", #selector(NSText.paste(_:)), "v")
    add(edit, "Select All", #selector(NSText.selectAll(_:)), "a")
    edit.addItem(.separator())
    add(edit, "Find…", #selector(find(_:)), "f", target: self)
    add(edit, "Find Next", #selector(nextMatch(_:)), "g", target: self)
    let window = menu("Window")
    add(
      window, "Session Overview…", #selector(sessionOverview(_:)), "p", [.command, .shift],
      target: self)
    add(window, "Minimize", #selector(NSWindow.performMiniaturize(_:)), "m")
    add(window, "Next Pane", #selector(focusPane(_:)), "\t", [.control], target: self)
    add(window, "Next Tab", #selector(NSWindow.selectNextTab(_:)), "]", [.command, .shift])
    add(window, "Previous Tab", #selector(NSWindow.selectPreviousTab(_:)), "[", [.command, .shift])
    add(window, "Show Tab Bar", #selector(NSWindow.toggleTabBar(_:)))
    let help = menu("Help")
    add(help, "Specter Handbook", #selector(showHandbook(_:)), target: self)
    NSApp.helpMenu = help
    NSApp.windowsMenu = window
    NSApp.mainMenu = main
  }
}
