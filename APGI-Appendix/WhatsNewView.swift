import SwiftUI

struct WhatsNewView: View {
  @Environment(\.dismiss) private var dismiss

  private let updates = [
    Update(
      version: "1.2.0",
      date: "January 2026",
      title: "Major Network Integration",
      features: [
        "Real-time network status monitoring",
        "Remote glossary and bibliography fetching",
        "Automatic content updates",
        "Enhanced search capabilities",
        "Network settings panel"
      ]
    ),
    Update(
      version: "1.1.0",
      date: "December 2025",
      title: "Table Parser System",
      features: [
        "Dynamic table parsing from multiple formats",
        "Markdown, CSV, TSV, and JSON support",
        "Export capabilities for all table formats",
        "Eliminated hardcoded table data"
      ]
    ),
    Update(
      version: "1.0.0",
      date: "November 2025",
      title: "Initial Release",
      features: [
        "Complete APGI framework reference",
        "Interactive navigation system",
        "Comprehensive search functionality",
        "Accessibility features throughout"
      ]
    )
  ]

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Spacer()
        Button("Done") {
          self.dismiss()
        }
        .buttonStyle(.bordered)
      }
      .padding()

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          self.header

          LazyVStack(spacing: 16) {
            ForEach(self.updates) { update in
              UpdateCard(update: update)
            }

            self.footer
          }
          .padding()
        }
      }
    }
    .frame(minWidth: 600, minHeight: 500)
  }

  private var header: some View {
    VStack(spacing: 16) {
      Image(systemName: "star.circle.fill")
        .font(.system(size: 48))
        .foregroundColor(.blue)

      Text("APGI Appendix Updates")
        .font(.title.bold())

      Text("Stay up to date with the latest features and improvements")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.bottom, 8)
  }

  private var footer: some View {
    VStack(spacing: 12) {
      Divider()

      Text("Thank you for using APGI Appendix!")
        .font(.subheadline)
        .foregroundColor(.secondary)

      HStack(spacing: 24) {
        SafeLink(
          title: "Online Documentation",
          urlString: "https://apgiframework.com",
          fallbackTitle: "Local Documentation"
        ) {
          self.showLocalDocumentation()
        }

        SafeLink(
          title: "Report Issues",
          urlString: "https://github.com/apgiframework/APGI-Appendix/issues",
          fallbackTitle: "Local Support"
        ) {
          self.showLocalSupport()
        }
      }
      .font(.caption)
    }
  }

  private func showLocalDocumentation() {
    let docContent = URLValidator.shared.getLocalHelpContent()

    let docWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )

    docWindow.title = "APGI Documentation"
    docWindow.center()
    docWindow.setFrameAutosaveName("DocumentationWindow")

    let docView = ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text(docContent)
          .font(.system(size: 14, design: .monospaced))
          .textSelection(.enabled)
          .padding()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }

    docWindow.contentView = NSHostingView(rootView: docView)
    docWindow.makeKeyAndOrderFront(nil)
  }

  private func showLocalSupport() {
    let alert = NSAlert()
    alert.messageText = "APGI Appendix Support"
    alert.informativeText = """
      For support with APGI Appendix:

      1. Check the built-in help documentation (⌘?)
      2. Use the search function to find specific topics
      3. Explore the glossary for terminology
      4. Try the interactive simulator for hands-on learning

      If you continue to experience issues, please:
      - Restart the application
      - Check for updates in Settings
      - Contact your system administrator

      Note: External links are currently unavailable. All features are available locally within the application.
      """
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}

struct UpdateCard: View {
  let update: Update

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(self.update.title)
            .font(.headline.bold())

          Text("Version \(self.update.version) • \(self.update.date)")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(self.update.version)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.1))
          .foregroundColor(.blue)
          .cornerRadius(6)
      }

      VStack(alignment: .leading, spacing: 6) {
        ForEach(self.update.features, id: \.self) { feature in
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
              .font(.caption)
              .foregroundColor(.green)
              .padding(.top, 2)

            Text(feature)
              .font(.body)
          }
        }
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
  }
}

struct Update: Identifiable {
  let id = UUID()
  let version: String
  let date: String
  let title: String
  let features: [String]
}

#Preview {
  WhatsNewView()
}
