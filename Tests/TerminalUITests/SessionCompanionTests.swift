import Foundation
import Testing

@testable import TerminalUI

struct SessionCompanionTests {
  @Test @MainActor func terminalsWithTheSameProfileKeepIndependentChoices() {
    var profile = Profile()
    let first = SessionCompanion(profile: profile)
    let second = SessionCompanion(profile: profile)
    first.selection.style = .moth
    first.selection.motion = .working
    first.selection.animated = false
    #expect(second.selection == CompanionSelection(profile: profile))
    profile.mascot = .rover
    let third = SessionCompanion(profile: profile)
    #expect(first.selection.style == .moth)
    #expect(second.selection.style == .wisp)
    #expect(third.selection.style == .rover)
    #expect(first.id != second.id)
  }

  @Test @MainActor func openGalleryKeepsItsTerminalWhenFocusMovesOrCompanionIsOff() {
    let first = SessionCompanion(profile: Profile())
    let second = SessionCompanion(profile: Profile())
    let strip = CompanionState()
    strip.session = first
    strip.gallery = first
    strip.session = second
    strip.gallery?.selection.style = .none
    #expect(first.selection.style == .none)
    #expect(second.selection.style == .wisp)
    #expect(strip.session === second)
    #expect(strip.gallery === first)
  }

  @Test @MainActor func layoutSelectionsRoundTripAndNotifyTheirOwner() throws {
    let terminal = SessionCompanion(profile: Profile())
    var changes = 0
    terminal.onChange = { changes += 1 }
    terminal.selection.style = .jelly
    terminal.selection.motion = .celebrate
    terminal.selection.animated = false
    #expect(changes == 3)
    let values = [terminal.selection, CompanionSelection(profile: Profile())]
    let decoded = try JSONDecoder().decode(
      [CompanionSelection].self,
      from: JSONEncoder().encode(values))
    #expect(decoded == values)
    let future = try JSONDecoder().decode(
      CompanionSelection.self,
      from: Data(#"{"style":"future","motion":"unknown","animated":false}"#.utf8))
    #expect(future.style == .wisp)
    #expect(future.motion == .idle)
    #expect(!future.animated)
  }
}
