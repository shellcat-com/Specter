import AppKit
import MetalTerminal
import SwiftUI

public struct Profile: Codable, Identifiable, Equatable {
  public var id = UUID()
  public var name = "Default"
  public var shell = ""
  public var directory = ""
  public var fontName = "Menlo"
  public var fontSize: Double = 14
  public var ligatures = false
  public var cursorStyle = "block"
  public var themeID = "system"
  public var scrollback = 10_000
  public init() {}
  private enum CodingKeys: String, CodingKey {
    case id, name, shell, directory, fontName, fontSize, ligatures, cursorStyle, themeID, scrollback
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Default"
    shell = try c.decodeIfPresent(String.self, forKey: .shell) ?? ""
    directory = try c.decodeIfPresent(String.self, forKey: .directory) ?? ""
    fontName = try c.decodeIfPresent(String.self, forKey: .fontName) ?? "Menlo"
    fontSize = max(8, min(40, try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? 14))
    ligatures = try c.decodeIfPresent(Bool.self, forKey: .ligatures) ?? false
    cursorStyle = try c.decodeIfPresent(String.self, forKey: .cursorStyle) ?? "block"
    themeID = try c.decodeIfPresent(String.self, forKey: .themeID) ?? "system"
    scrollback = max(
      1000, min(100_000, try c.decodeIfPresent(Int.self, forKey: .scrollback) ?? 10_000))
  }
}

@MainActor
public final class Preferences: ObservableObject {
  public static let shared = Preferences()
  @Published public var profiles: [Profile] { didSet { save() } }
  @Published public var selectedProfile: UUID {
    didSet { UserDefaults.standard.set(selectedProfile.uuidString, forKey: "selectedProfile") }
  }
  @Published public var restoreWindows: Bool {
    didSet { UserDefaults.standard.set(restoreWindows, forKey: "restoreWindows") }
  }
  @Published public var customThemes: [Theme] {
    didSet {
      if let data = try? JSONEncoder().encode(customThemes) {
        UserDefaults.standard.set(data, forKey: "themes")
      }
    }
  }
  public var themes: [Theme] { Theme.builtins + customThemes }
  public var active: Profile { profiles.first { $0.id == selectedProfile } ?? profiles[0] }
  private init() {
    let stored = UserDefaults.standard.data(forKey: "profiles").flatMap {
      try? JSONDecoder().decode([Profile].self, from: $0)
    }
    let initialProfiles = (stored?.isEmpty == false ? stored! : [Profile()])
    profiles = initialProfiles
    selectedProfile =
      UserDefaults.standard.string(forKey: "selectedProfile").flatMap(UUID.init(uuidString:))
      ?? initialProfiles[0].id
    restoreWindows = UserDefaults.standard.bool(forKey: "restoreWindows")
    customThemes =
      UserDefaults.standard.data(forKey: "themes").flatMap {
        try? JSONDecoder().decode([Theme].self, from: $0)
      }?.filter { $0.validate() } ?? []
  }
  private func save() {
    if let data = try? JSONEncoder().encode(profiles) {
      UserDefaults.standard.set(data, forKey: "profiles")
    }
    NotificationCenter.default.post(name: .specterPreferencesChanged, object: nil)
  }
  public func theme(for profile: Profile, dark: Bool) -> Theme {
    themes.first { $0.id == profile.themeID } ?? Theme.builtins[dark ? 0 : 1]
  }
  public func importTheme() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.json]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
      guard size <= 65_536 else { throw CocoaError(.fileReadTooLarge) }
      let theme = try JSONDecoder().decode(Theme.self, from: Data(contentsOf: url))
      guard theme.validate(), !Theme.builtins.contains(where: { $0.id == theme.id }) else {
        throw CocoaError(.fileReadCorruptFile)
      }
      customThemes.removeAll { $0.id == theme.id }
      customThemes.append(theme)
    } catch { NSAlert(error: error).runModal() }
  }
  public func exportTheme() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "specter-theme.json"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      try encoder.encode(theme(for: active, dark: true)).write(to: url, options: .atomic)
    } catch { NSAlert(error: error).runModal() }
  }
}
extension Notification.Name {
  public static let specterPreferencesChanged = Notification.Name("SpecterPreferencesChanged")
}

public struct SettingsView: View {
  @AppStorage("bellNotifications") private var bellNotifications = false
  @ObservedObject private var preferences = Preferences.shared
  public init() {}
  public var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading) {
        Text("Profiles").font(.headline).padding(.horizontal)
        List(selection: $preferences.selectedProfile) {
          ForEach(preferences.profiles) { profile in Text(profile.name).tag(profile.id) }
        }
        HStack {
          Button {
            let profile = Profile()
            preferences.profiles.append(profile)
            preferences.selectedProfile = profile.id
          } label: {
            Image(systemName: "plus")
          }.help("Add profile")
          Button {
            if preferences.profiles.count > 1 {
              preferences.profiles.removeAll { $0.id == preferences.selectedProfile }
              preferences.selectedProfile = preferences.profiles[0].id
            }
          } label: {
            Image(systemName: "minus")
          }.disabled(preferences.profiles.count == 1).help("Remove profile")
        }.padding(.horizontal)
      }.frame(width: 160).padding(.vertical)
      Divider()
      if let index = preferences.profiles.firstIndex(where: { $0.id == preferences.selectedProfile }
      ) {
        Form {
          Section("Session") {
            TextField("Profile name", text: $preferences.profiles[index].name)
            TextField(
              "Shell", text: $preferences.profiles[index].shell, prompt: Text("User login shell"))
            TextField(
              "Working directory", text: $preferences.profiles[index].directory,
              prompt: Text("Home directory"))
            Text("Shell and directory changes apply to new sessions.").font(.caption)
              .foregroundStyle(.secondary)
          }
          Section("Appearance") {
            TextField("Font", text: $preferences.profiles[index].fontName)
            Stepper(
              "Size: \(Int(preferences.profiles[index].fontSize)) pt",
              value: $preferences.profiles[index].fontSize, in: 8...40)
            Toggle("Programming ligatures", isOn: $preferences.profiles[index].ligatures)
            Picker("Cursor", selection: $preferences.profiles[index].cursorStyle) {
              Text("Block").tag("block")
              Text("Bar").tag("bar")
              Text("Underline").tag("underline")
            }
            Picker("Theme", selection: $preferences.profiles[index].themeID) {
              Text("System appearance").tag("system")
              ForEach(preferences.themes) { Text($0.name).tag($0.id) }
            }
            HStack {
              Button("Import theme…") { preferences.importTheme() }
              Button("Export theme…") { preferences.exportTheme() }
            }
          }
          Section("History and restoration") {
            Stepper(
              "Scrollback: \(preferences.profiles[index].scrollback) rows",
              value: $preferences.profiles[index].scrollback, in: 1000...100_000, step: 1000)
            Toggle("Reopen window layouts with fresh shells", isOn: $preferences.restoreWindows)
            Toggle("Notify for background terminal bells", isOn: $bellNotifications).onChange(
              of: bellNotifications
            ) { _, enabled in BellNotifications.setEnabled(enabled) }
            Text(
              "Terminal output and commands are never saved. Restoration saves window layout and profile identifiers."
            ).font(.caption).foregroundStyle(.secondary)
          }
        }.formStyle(.grouped).frame(width: 470)
      }
    }.frame(width: 640, height: 600)
  }
}
