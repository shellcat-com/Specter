import AppKit
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
  @Test func profileMigrationDefaultsNewFields() throws {
    let data = Data("{\"name\":\"Legacy\",\"fontSize\":200}".utf8)
    let profile = try JSONDecoder().decode(Profile.self, from: data)
    #expect(profile.name == "Legacy")
    #expect(profile.fontSize == 40)
    #expect(!profile.ligatures)
    #expect(profile.scrollback == 10_000)
    let roundtrip = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
    #expect(roundtrip == profile)
  }
}
