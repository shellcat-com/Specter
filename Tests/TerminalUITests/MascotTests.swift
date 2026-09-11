import Foundation
import Testing

@testable import TerminalUI

struct MascotTests {
  @Test func legacyCompanionsMigrateWithoutEnablingAnimation() throws {
    let mappings = [
      "specter": MascotStyle.wisp, "comet": .cinder, "sprout": .moss, "pixel": .rover,
      "none": .none,
    ]
    for (legacy, expected) in mappings {
      let data = try JSONSerialization.data(withJSONObject: [
        "mascot": legacy, "animateMascot": false,
      ])
      let profile = try JSONDecoder().decode(Profile.self, from: data)
      #expect(profile.mascot == expected)
      #expect(profile.mascotMotion == .idle)
      #expect(!profile.animateMascot)
    }
    let future = try JSONDecoder().decode(
      Profile.self, from: Data(#"{"mascotMotion":"future"}"#.utf8))
    #expect(future.mascotMotion == .idle)
    for motion in MascotMotion.allCases {
      var profile = Profile()
      profile.mascotMotion = motion
      let restored = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
      #expect(restored == profile)
    }
  }

  @Test @MainActor func bundledFramesCoverEveryPickerChoiceAndMotion() throws {
    let catalog = try MascotCatalog.bundled.get()
    #expect(Set(catalog.sprites.keys) == Set(MascotStyle.allCases.filter { $0 != .none }))
    for sprite in catalog.sprites.values {
      #expect(sprite.colors.count == 3)
      for motion in MascotMotion.allCases {
        let frames = try #require(sprite.frames[motion])
        #expect(frames.count == 12)
        #expect(frames.allSatisfy { $0.count == 3 && !$0[0].isEmpty })
      }
    }
  }

  @Test @MainActor func malformedCatalogIsRejected() throws {
    var json = try #require(
      JSONSerialization.jsonObject(with: MascotCatalog.resourceData()) as? [String: Any])
    json["width"] = 25
    let invalid = try JSONSerialization.data(withJSONObject: json)
    #expect(throws: MascotCatalogError.self) { try MascotCatalog(data: invalid) }
    #expect(throws: MascotCatalogError.self) {
      try MascotCatalog(data: Data(repeating: 0, count: 524_289))
    }
  }

  @Test func playbackPausesResumesAndWrapsWithoutCatchingUp() {
    var clock = MascotPlaybackClock()
    #expect(clock.frame(at: 100) == 0)
    clock.setPlaying(true, at: 100)
    #expect(clock.frame(at: 100.5) == 4)
    clock.setPlaying(false, at: 100.5)
    #expect(clock.frame(at: 10_000) == 4)
    clock.setPlaying(true, at: 10_000)
    #expect(clock.frame(at: 10_000.125) == 5)
    #expect(clock.frame(at: 10_001) == 0)
    clock.setPlaying(true, at: 10_001)
    #expect(clock.frame(at: 10_001.125) == 1)
  }
}
