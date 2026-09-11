import SwiftUI

/// Settings edits defaults; a terminal gallery edits that terminal's independent selection.
struct CompanionGalleryView: View {
  let profileID: UUID
  @ObservedObject private var preferences = Preferences.shared
  var body: some View {
    if let index = preferences.profiles.firstIndex(where: { $0.id == profileID }) {
      CompanionGalleryContent(
        selection: Binding(
          get: { CompanionSelection(profile: preferences.profiles[index]) },
          set: { value in
            preferences.profiles[index].mascot = value.style
            preferences.profiles[index].mascotMotion = value.motion
            preferences.profiles[index].animateMascot = value.animated
          }), scope: "Defaults for new terminals · \(preferences.profiles[index].name)")
    } else {
      ContentUnavailableView(
        "Profile removed", systemImage: "person.crop.circle.badge.questionmark",
        description: Text("Close this gallery and choose an existing profile.")
      )
      .frame(width: 640, height: 730)
    }
  }
}

struct CompanionGalleryContent: View {
  @Binding var selection: CompanionSelection
  let scope: String
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
      if let catalog = MascotCatalog.available {
        HStack(spacing: 16) {
          MascotView(
            style: selection.style, motion: selection.motion, animated: selection.animated
          )
          .frame(width: 96, height: 96)
          VStack(alignment: .leading, spacing: 5) {
            Text(selection.style == .none ? "Companion is off" : selection.style.title).font(
              .headline)
            Text(
              catalog.sprites[selection.style]?.description
                ?? "Select a character below to bring the companion back."
            )
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Text(scope).font(.caption).foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
        }
        ScrollView {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
            ForEach(MascotStyle.allCases.filter { $0 != .none }) { style in
              Button {
                selection.style = style
              } label: {
                VStack(spacing: 0) {
                  MascotView(style: style, animated: false).frame(width: 72, height: 72)
                  HStack(spacing: 4) {
                    Text(style.title)
                    if selection.style == style { Image(systemName: "checkmark.circle.fill") }
                  }.font(.system(size: 12, weight: .medium)).frame(height: 20)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 5)
                .contentShape(Rectangle())
              }
              .buttonStyle(.bordered)
              .tint(selection.style == style ? .accentColor : .secondary)
              .accessibilityLabel("Choose \(style.title)")
              .accessibilityValue(selection.style == style ? "Selected" : "")
              .accessibilityAddTraits(selection.style == style ? .isSelected : [])
              .help(catalog.sprites[style]?.gesture ?? style.title)
            }
          }.padding(3)
        }
        Divider()
        HStack {
          Picker("Motion", selection: $selection.motion) {
            ForEach(MascotMotion.allCases) { Text($0.title).tag($0) }
          }.frame(width: 190).disabled(selection.style == .none)
          Toggle("Animate", isOn: $selection.animated)
            .disabled(selection.style == .none)
          Spacer()
          Button("Turn off") { selection.style = .none }
            .disabled(selection.style == .none)
        }
        Text("Motion is decorative. Reduce Motion keeps your companion still.")
          .font(.caption).foregroundStyle(.secondary)
      } else {
        ContentUnavailableView(
          "Companions unavailable", systemImage: "exclamationmark.triangle",
          description: Text(
            "The bundled character catalog could not be loaded. Rebuild or reinstall Specter."))
      }
    }.padding(24).frame(width: 640, height: 730)
  }
}
