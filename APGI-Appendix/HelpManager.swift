import Combine
import SwiftUI

class HelpContentManager: ObservableObject {
  static let shared = HelpContentManager()

  @Published var version: String = Bundle.main.appVersion

  private init() {}

  var canonicalHelpMarkdown: String {
    return """
      # APGI Appendix Help

      ## Quick Start

      1. **Navigation**: Use the sidebar to browse categories
      2. **Search**: Press ⌘F to search all content
      3. **Bookmarks**: Press ⌘B to bookmark current section
      4. **Focus Mode**: Click the eye icon for distraction-free reading

      ## Keyboard Shortcuts

      - ⌘F: Open search
      - ⌘B: Toggle bookmark
      - ⌘1-9: Navigate to tabs
      - ⌘/: Show keyboard shortcuts
      - ⌘G: Toggle glossary
      - ⌘⇧M: Open Simulator
      - ⌘⇧T: Open Timeline
      - ⌘, : Settings
      - ⌘⌥I: Toggle Inspector
      - ⌘⌥S: Toggle Sidebar

      ## Getting Started

      The APGI Appendix provides comprehensive information about the Adaptive Precision-Gated Ignition Framework. Start with:

      1. **Methodology** - Understand the framework approach
      2. **Glossary** - Learn key terminology
      3. **Timeline** - Explore historical developments
      4. **Neuromodulators** - Study biological implementations

      ## Troubleshooting

      - **Offline access**: Most content is cached, but interactive simulations may require network access for initial model weights.
      - **Performance**: High resolution simulations may require significant GPU memory. Use Apple Silicon for best results.

      ## Need More Help?

      Visit [docs.apgi-framework.org](https://docs.apgi-framework.org) for detailed information.
      """
  }
}

struct HelpView: View {
  @StateObject private var helpManager = HelpContentManager.shared

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Help & Documentation")
          .font(.title.bold())

        Spacer()
      }
      .padding()
      .background(.thinMaterial)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          let content = self.helpManager.canonicalHelpMarkdown

          if content.isEmpty {
            Text("No help content available")
              .foregroundStyle(.secondary)
              .padding()
          } else {
            LazyGlossaryHighlightedContent(text: content)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding()
      }
    }
  }
}

struct HelpSection: Identifiable, Codable {
  let id = UUID()
  let title: String
  let content: String
  let category: String
  let lastUpdated: String

  enum CodingKeys: String, CodingKey {
    case title, content, category, lastUpdated
  }
}

struct HelpSectionView: View {
  let section: HelpSection

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(self.section.title)
          .font(.headline)

        Spacer()

        Text("Updated: \(self.section.lastUpdated)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(self.section.content)
        .font(.body)
        .foregroundStyle(.secondary)
    }
    .padding()
    .background(.quaternary.opacity(0.5))
    .cornerRadius(8)
  }
}
