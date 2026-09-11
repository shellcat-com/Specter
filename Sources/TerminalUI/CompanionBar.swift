import SwiftUI

@MainActor
final class CompanionState: ObservableObject {
  @Published var session: SessionCompanion?
  @Published var isActive = false
  @Published var gallery: SessionCompanion?
}

struct CompanionBar: View {
  @ObservedObject var state: CompanionState
  let showThemes: () -> Void

  var body: some View {
    Group {
      if let session = state.session {
        TerminalCompanionBar(
          session: session, isActive: state.isActive,
          showGallery: { state.gallery = session }, showThemes: showThemes
        )
        .id(session.id)
      }
    }.sheet(item: $state.gallery) { session in
      TerminalCompanionGallery(session: session)
    }
  }
}

private struct TerminalCompanionBar: View {
  @ObservedObject var session: SessionCompanion
  let isActive: Bool
  let showGallery: () -> Void
  let showThemes: () -> Void

  var body: some View {
    if session.selection.style != .none {
      HStack(spacing: 10) {
        MascotView(
          style: session.selection.style, motion: session.selection.motion,
          animated: session.selection.animated && isActive
        )
        .frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 2) {
          Text("Hello, from \(session.selection.style.title).")
            .font(.system(size: 12, weight: .medium))
          Text("This terminal").font(.caption).foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        Button("Companions…", action: showGallery).controlSize(.small)
        Menu {
          Picker("Companion", selection: $session.selection.style) {
            ForEach(MascotStyle.allCases) { Text($0.title).tag($0) }
          }
          Picker("Motion", selection: $session.selection.motion) {
            ForEach(MascotMotion.allCases) { Text($0.title).tag($0) }
          }
          Toggle("Animate companion", isOn: $session.selection.animated)
        } label: {
          Image(systemName: "ellipsis")
        }
        .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Companion options")
        Button("Themes…", action: showThemes).controlSize(.small)
      }.padding(.horizontal, 12).frame(height: 60)
        .background(.background).overlay(alignment: .bottom) { Divider() }
    }
  }
}

private struct TerminalCompanionGallery: View {
  @ObservedObject var session: SessionCompanion
  var body: some View {
    CompanionGalleryContent(
      selection: $session.selection,
      scope: "This terminal only · other terminals keep their companions")
  }
}
