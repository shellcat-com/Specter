import SwiftUI

struct SessionEntry: Identifiable {
  let id: ObjectIdentifier
  let name: String
  let detail: String
  let activate: () -> Void
}

struct SessionOverview: View {
  let entries: [SessionEntry]
  let onDone: () -> Void
  @State private var query = ""
  @Environment(\.dismiss) private var dismiss
  private var matches: [SessionEntry] {
    entries.filter {
      query.isEmpty || "\($0.name) \($0.detail)".localizedCaseInsensitiveContains(query)
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text("Your workspace.").font(.system(size: 28, weight: .regular))
          Text("\(entries.count) sessions across your tabs and windows").foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { onDone() }.keyboardShortcut(.cancelAction)
      }
      TextField("Find a session", text: $query).textFieldStyle(.roundedBorder)
        .accessibilityLabel("Find a session")
      ScrollView {
        LazyVStack(spacing: 8) {
          ForEach(matches) { entry in
            Button {
              dismiss()
              entry.activate()
            } label: {
              HStack(spacing: 12) {
                Image(systemName: "terminal").font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                  Text(entry.name).fontWeight(.medium)
                  Text(entry.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
              }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
          }
        }
        if matches.isEmpty {
          ContentUnavailableView.search(text: query)
        }
      }
    }.padding(24).frame(width: 620, height: 540)
  }
}
