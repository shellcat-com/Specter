import AppKit
import MetalTerminal
import Testing

@testable import TerminalUI

struct NativeTests {
  @Test @MainActor func splitPaneHitTestingAndIMEComposition() {
    _ = NSApplication.shared
    let parent = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 500))
    let view = TerminalView(profile: Profile())
    view.frame = NSRect(x: 450, y: 0, width: 450, height: 500)
    parent.addSubview(view)
    #expect(view.hitTest(NSPoint(x: 600, y: 100)) === view)
    #expect(view.hitTest(NSPoint(x: 300, y: 100)) == nil)
    view.setMarkedText(
      "日本", selectedRange: NSRange(location: 2, length: 0),
      replacementRange: NSRange(location: NSNotFound, length: 0))
    #expect(view.hasMarkedText())
    #expect(view.markedRange() == NSRange(location: 0, length: 2))
    view.unmarkText()
    #expect(!view.hasMarkedText())
    view.close()
  }
  @Test @MainActor func appearanceMenusKeepStableItemsAndExposeEveryTheme() {
    _ = NSApplication.shared
    let application = SpecterApplication()
    let menu = NSMenu(title: "New Window with Theme")
    application.menuNeedsUpdate(menu)
    #expect(menu.numberOfItems == 3)
    let basic = menu.items.first
    let themes = menu.items.dropFirst().flatMap { $0.submenu?.items ?? [] }
    #expect(themes.count == Preferences.shared.themes.count)
    application.menuNeedsUpdate(menu)
    #expect(menu.items.first === basic)
    let profiles = NSMenu(title: "New Tab with Profile")
    application.menuNeedsUpdate(profiles)
    #expect(profiles.numberOfItems == Preferences.shared.profiles.count)
    #expect(profiles.items.allSatisfy { $0.tag == 1 })
  }
  @Test func companionPreferencesSurviveRoundtripAndUnknownDesign() throws {
    for style in MascotStyle.allCases {
      var profile = Profile()
      profile.mascot = style
      profile.animateMascot = false
      let restored = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
      #expect(restored == profile)
    }
    let unknown = try JSONDecoder().decode(
      Profile.self, from: Data("{\"mascot\":\"future-design\"}".utf8))
    #expect(unknown.mascot == .specter)
  }
  @Test func customContrastAndColorValidation() {
    var theme = Theme.builtins[0]
    theme.background = "#000000"
    theme.foreground = "#FFFFFF"
    #expect(abs(theme.defaultTextContrast - 21) < 0.001)
    theme.foreground = theme.background
    #expect(theme.defaultTextContrast == 1)
    theme.foreground = "#invalid"
    #expect(!theme.validate())
    #expect(Theme.builtins.allSatisfy { $0.defaultTextContrast >= 7 })
  }
  @Test func profileMigrationDefaultsNewFields() throws {
    let data = Data("{\"name\":\"Legacy\",\"fontSize\":200}".utf8)
    let profile = try JSONDecoder().decode(Profile.self, from: data)
    #expect(profile.name == "Legacy")
    #expect(profile.fontSize == 40)
    #expect(profile.mascot == .specter)
    #expect(profile.animateMascot)
    #expect(!profile.ligatures)
    #expect(profile.scrollback == 10_000)
    let roundtrip = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
    #expect(roundtrip == profile)
  }
}
