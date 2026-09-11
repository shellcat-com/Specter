import SwiftUI

@MainActor
final class CompanionState: ObservableObject {
  @Published var profileID: UUID
  @Published var isActive = false
  init(profileID: UUID) { self.profileID = profileID }
}

struct CompanionBar: View {
  @ObservedObject var state: CompanionState
  @ObservedObject private var preferences = Preferences.shared
  let showThemes: () -> Void
  @State private var gallery: CompanionGalleryDestination?

  var body: some View {
    Group {
      if let index = preferences.profiles.firstIndex(where: { $0.id == state.profileID }),
        preferences.profiles[index].mascot != .none
      {
        let profile = preferences.profiles[index]
        HStack(spacing: 10) {
          MascotView(
            style: profile.mascot, motion: profile.mascotMotion,
            animated: profile.animateMascot && state.isActive
          )
          .frame(width: 48, height: 48)
          VStack(alignment: .leading, spacing: 2) {
            Text("Hello, from \(profile.mascot.title).")
              .font(.system(size: 12, weight: .medium))
            Text(profile.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
          }
          Spacer(minLength: 0)
          Menu {
            Button("Browse companions…") {
              gallery = CompanionGalleryDestination(profileID: profile.id)
            }
            Picker("Companion", selection: $preferences.profiles[index].mascot) {
              ForEach(MascotStyle.allCases) { Text($0.title).tag($0) }
            }
            Picker("Motion", selection: $preferences.profiles[index].mascotMotion) {
              ForEach(MascotMotion.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Animate companion", isOn: $preferences.profiles[index].animateMascot)
          } label: {
            Image(systemName: "face.smiling")
          }
          .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Choose companion")
          Button("Themes…", action: showThemes).controlSize(.small)
        }.padding(.horizontal, 12).frame(height: 60)
          .background(.background).overlay(alignment: .bottom) { Divider() }
      }
    }.sheet(item: $gallery) { destination in
      CompanionGalleryView(profileID: destination.profileID)
    }
  }
}
