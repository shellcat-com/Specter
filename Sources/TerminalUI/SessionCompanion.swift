import SwiftUI

/// A terminal owns its choice. Profiles only supply defaults when that terminal is created.
struct CompanionSelection: Codable, Equatable {
  var style: MascotStyle
  var motion: MascotMotion
  var animated: Bool

  init(profile: Profile) {
    style = profile.mascot
    motion = profile.mascotMotion
    animated = profile.animateMascot
  }

  private enum CodingKeys: String, CodingKey { case style, motion, animated }
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    style = MascotStyle.restored(from: try values.decodeIfPresent(String.self, forKey: .style))
    motion =
      (try values.decodeIfPresent(String.self, forKey: .motion))
      .flatMap(MascotMotion.init(rawValue:)) ?? .idle
    animated = try values.decodeIfPresent(Bool.self, forKey: .animated) ?? true
  }
}

@MainActor
final class SessionCompanion: ObservableObject, Identifiable {
  let id = UUID()
  let profileID: UUID
  @Published var selection: CompanionSelection { didSet { onChange?() } }
  var onChange: (() -> Void)?

  init(profile: Profile) {
    profileID = profile.id
    selection = CompanionSelection(profile: profile)
  }
}
