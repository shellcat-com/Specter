import SwiftUI

struct CompanionGalleryDestination: Identifiable {
  let profileID: UUID
  var id: UUID { profileID }
}

/// The destination captures the profile ID so focus changes cannot retarget an open gallery.
struct CompanionGalleryView: View {
  let profileID: UUID
  @ObservedObject private var preferences = Preferences.shared
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("A little company.").font(.system(size: 26, weight: .regular))
          Text("12 characters. Find your favorite.").foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
      }
      if let index = preferences.profiles.firstIndex(where: { $0.id == profileID }) {
        let profile = preferences.profiles[index]
        if let catalog = MascotCatalog.available {
          HStack(spacing: 16) {
            MascotView(
              style: profile.mascot, motion: profile.mascotMotion, animated: profile.animateMascot
            )
            .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 5) {
              Text(profile.mascot == .none ? "Companion is off" : profile.mascot.title).font(
                .headline)
              Text(
                catalog.sprites[profile.mascot]?.description
                  ?? "Select a character below to bring the companion back."
              )
              .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
              Text("Applying to \(profile.name)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
          ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
              ForEach(MascotStyle.allCases.filter { $0 != .none }) { style in
                Button {
                  preferences.profiles[index].mascot = style
                } label: {
                  VStack(spacing: 0) {
                    MascotView(style: style, animated: false).frame(width: 72, height: 72)
                    HStack(spacing: 4) {
                      Text(style.title)
                      if profile.mascot == style { Image(systemName: "checkmark.circle.fill") }
                    }.font(.system(size: 12, weight: .medium)).frame(height: 20)
                  }
                  .frame(maxWidth: .infinity).padding(.vertical, 5)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(profile.mascot == style ? .accentColor : .secondary)
                .accessibilityLabel("Choose \(style.title)")
                .accessibilityValue(profile.mascot == style ? "Selected" : "")
                .accessibilityAddTraits(profile.mascot == style ? .isSelected : [])
                .help(catalog.sprites[style]?.gesture ?? style.title)
              }
            }.padding(3)
          }
          Divider()
          HStack {
            Picker("Motion", selection: $preferences.profiles[index].mascotMotion) {
              ForEach(MascotMotion.allCases) { Text($0.title).tag($0) }
            }.frame(width: 190).disabled(profile.mascot == .none)
            Toggle("Animate", isOn: $preferences.profiles[index].animateMascot)
              .disabled(profile.mascot == .none)
            Spacer()
            Button("Turn off") { preferences.profiles[index].mascot = .none }
              .disabled(profile.mascot == .none)
          }
          Text("Motion is decorative. Reduce Motion keeps your companion still.")
            .font(.caption).foregroundStyle(.secondary)
        } else {
          ContentUnavailableView(
            "Companions unavailable", systemImage: "exclamationmark.triangle",
            description: Text(
              "The bundled character catalog could not be loaded. Rebuild or reinstall Specter."))
        }
      } else {
        ContentUnavailableView(
          "Profile removed", systemImage: "person.crop.circle.badge.questionmark",
          description: Text("Close this gallery and choose an existing profile."))
      }
    }.padding(24).frame(width: 640, height: 730)
  }
}
