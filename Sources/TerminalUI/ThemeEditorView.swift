import AppKit
import MetalTerminal
import SwiftUI

/// Edits a private draft; Cancel leaves the live profile and catalog untouched.
struct ThemeEditorView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var draft: Theme
  @ObservedObject private var preferences = Preferences.shared
  let profileID: UUID
  init(theme: Theme, profileID: UUID) {
    var copy = theme
    copy.id = "custom-" + UUID().uuidString.lowercased()
    copy.name = String((theme.name + " Custom").prefix(100))
    _draft = State(initialValue: copy)
    self.profileID = profileID
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Make it yours.").font(.title)
      Text(
        "Save a new palette for \(preferences.profiles.first { $0.id == profileID }?.name ?? "this profile")."
      )
      .foregroundStyle(.secondary)
      ThemePreview(theme: draft).frame(height: 145)
      Form {
        TextField("Name", text: $draft.name)
        Toggle("Dark appearance", isOn: $draft.isDark)
        colorRow("Background", hex: $draft.background)
        colorRow("Text", hex: $draft.foreground)
        colorRow("Cursor", hex: $draft.cursor)
        colorRow("Selection", hex: $draft.selection)
        Section("ANSI colors · normal and bright") {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
            ForEach(0..<16) { index in
              colorRow("ANSI \(index)", hex: $draft.palette[index])
            }
          }
        }
      }.formStyle(.grouped)
      Text(
        draft.validate()
          ? String(
            format:
              "Default text contrast: %.2f:1 · Aim for 7:1. ANSI colors need separate review.",
            draft.defaultTextContrast)
          : "Enter a name (1–100 characters) and six-digit #RRGGBB colors to save."
      )
      .font(.caption).foregroundStyle(.secondary)
      HStack {
        Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
        Spacer()
        Button("Save & Apply") {
          guard draft.validate(),
            let index = preferences.profiles.firstIndex(where: { $0.id == profileID })
          else { return }
          preferences.customThemes.append(draft)
          preferences.profiles[index].themeID = draft.id
          dismiss()
        }.keyboardShortcut(.defaultAction)
          .disabled(
            !draft.validate() || !preferences.profiles.contains(where: { $0.id == profileID }))
      }
    }.padding(24).frame(width: 560, height: 730)
  }
  private func colorRow(_ title: String, hex: Binding<String>) -> some View {
    HStack {
      ColorPicker(
        title,
        selection: Binding(
          get: {
            Color(
              nsColor: NSColor(
                srgbRed: Double(Theme.rgba(hex.wrappedValue).x),
                green: Double(Theme.rgba(hex.wrappedValue).y),
                blue: Double(Theme.rgba(hex.wrappedValue).z), alpha: 1))
          },
          set: { color in
            guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
            func byte(_ component: CGFloat) -> Int {
              Int((max(0, min(1, component)) * 255).rounded())
            }
            hex.wrappedValue = String(
              format: "#%02X%02X%02X", byte(rgb.redComponent),
              byte(rgb.greenComponent), byte(rgb.blueComponent))
          }), supportsOpacity: false)
      TextField(title + " hex", text: hex).labelsHidden().frame(width: 78)
        .font(.system(.caption, design: .monospaced)).accessibilityLabel(
          title + " hexadecimal color")
    }
  }
}

extension Theme {
  var defaultTextContrast: Double {
    func luminance(_ hex: String) -> Double {
      let rgb = Theme.rgba(hex)
      func linear(_ value: Float) -> Double {
        let channel = Double(value)
        if channel <= 0.04045 { return channel / 12.92 }
        return Foundation.pow((channel + 0.055) / 1.055, 2.4)
      }
      let values: [Double] = [linear(rgb.x), linear(rgb.y), linear(rgb.z)]
      return values[0] * 0.2126 + values[1] * 0.7152 + values[2] * 0.0722
    }
    let a = luminance(background)
    let b = luminance(foreground)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }
}
