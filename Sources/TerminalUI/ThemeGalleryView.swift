import Foundation
import MetalTerminal
import SwiftUI

/// Previews contain synthetic text only. Applying a theme updates the selected profile.
public struct ThemeGalleryView: View {
  @ObservedObject private var preferences = Preferences.shared
  @Environment(\.dismiss) private var dismiss
  @AppStorage("favoriteThemeIDs") private var favoriteIDs = "[]"
  @State private var editingTheme: Theme?
  @State private var editingProfileID = UUID()
  @Environment(\.colorScheme) private var colorScheme
  @State private var query = ""
  @State private var appearance = "All"
  @State private var favoritesOnly = false
  private let onDone: (() -> Void)?
  public init(onDone: (() -> Void)? = nil) { self.onDone = onDone }
  private var favorites: Set<String> {
    Set((try? JSONDecoder().decode([String].self, from: Data(favoriteIDs.utf8))) ?? [])
  }
  private var filtered: [Theme] {
    preferences.themes.filter {
      (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query))
        && (appearance == "All" || $0.isDark == (appearance == "Dark"))
        && (!favoritesOnly || favorites.contains($0.id))
    }
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Find your atmosphere.").font(.system(size: 28, weight: .regular))
          Text("\(preferences.themes.count) themes · Applying to \(preferences.active.name)")
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { if let onDone { onDone() } else { dismiss() } }.keyboardShortcut(
          .cancelAction)
      }
      HStack {
        TextField("Search themes", text: $query).textFieldStyle(.roundedBorder)
          .accessibilityLabel("Search themes")
        Picker("Appearance", selection: $appearance) {
          Text("All").tag("All")
          Text("Dark").tag("Dark")
          Text("Light").tag("Light")
        }.pickerStyle(.segmented).labelsHidden().accessibilityLabel("Appearance").frame(width: 200)
        Toggle("Favorites", isOn: $favoritesOnly).toggleStyle(.button)
      }
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) {
          ForEach(filtered) { theme in
            VStack(alignment: .leading, spacing: 8) {
              Button {
                if let index = preferences.profiles.firstIndex(where: {
                  $0.id == preferences.selectedProfile
                }) {
                  preferences.profiles[index].themeID = theme.id
                }
              } label: {
                ThemePreview(theme: theme)
                  .overlay(
                    RoundedRectangle(cornerRadius: 10).stroke(
                      preferences.active.themeID == theme.id
                        ? Color.accentColor : Color.secondary.opacity(0.25),
                      lineWidth: preferences.active.themeID == theme.id ? 3 : 1))
              }.buttonStyle(.plain)
                .accessibilityLabel("Apply \(theme.name)")
                .accessibilityAddTraits(preferences.active.themeID == theme.id ? .isSelected : [])
              HStack {
                Text(theme.name).font(.system(size: 12, weight: .medium))
                Spacer()
                Button {
                  var updated = favorites
                  if updated.contains(theme.id) {
                    updated.remove(theme.id)
                  } else {
                    updated.insert(theme.id)
                  }
                  if let data = try? JSONEncoder().encode(updated.sorted()) {
                    favoriteIDs = String(decoding: data, as: UTF8.self)
                  }
                } label: {
                  Image(systemName: favorites.contains(theme.id) ? "star.fill" : "star")
                }.buttonStyle(.borderless)
                  .accessibilityLabel(
                    "\(favorites.contains(theme.id) ? "Unfavorite" : "Favorite") \(theme.name)")
              }
            }.padding(3)
          }
        }.padding(3)
        if filtered.isEmpty {
          ContentUnavailableView(
            "No matching themes", systemImage: "paintpalette",
            description: Text("Try another name, appearance, or turn off Favorites."))
        }
      }
      HStack {
        Text("\(filtered.count) \(filtered.count == 1 ? "theme" : "themes")").font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Customize current…") {
          editingProfileID = preferences.active.id
          editingTheme = preferences.theme(for: preferences.active, dark: colorScheme == .dark)
        }
        Button("Follow system appearance") {
          if let index = preferences.profiles.firstIndex(where: {
            $0.id == preferences.selectedProfile
          }) {
            preferences.profiles[index].themeID = "system"
          }
        }
      }
    }.padding(24)
      .sheet(item: $editingTheme) { theme in
        ThemeEditorView(theme: theme, profileID: editingProfileID)
      }
  }
}

struct ThemePreview: View {
  let theme: Theme
  private func color(_ hex: String) -> Color {
    let rgba = Theme.rgba(hex)
    return Color(red: Double(rgba.x), green: Double(rgba.y), blue: Double(rgba.z))
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("~/studio  ·  main").foregroundStyle(color(theme.foreground).opacity(0.75))
      HStack(spacing: 6) {
        Text("❯").foregroundStyle(color(theme.palette[2]))
        Text("swift build").foregroundStyle(color(theme.foreground))
      }
      Text("Build complete.").foregroundStyle(color(theme.palette[2]))
      HStack(spacing: 0) {
        ForEach(0..<8) { i in color(theme.palette[i]).frame(height: 9) }
      }.clipShape(RoundedRectangle(cornerRadius: 3)).padding(.top, 5)
    }.font(.system(size: 12, design: .monospaced))
      .frame(maxWidth: .infinity, alignment: .leading).padding(16)
      .background(color(theme.background), in: RoundedRectangle(cornerRadius: 10))
      .accessibilityHidden(true)
  }
}
