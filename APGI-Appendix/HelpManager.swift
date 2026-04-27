import Combine
import SwiftUI

class HelpContentManager: ObservableObject {
  static let shared = HelpContentManager()

  @Published var version: String = Bundle.main.appVersion
  @Published var remoteHelpMarkdown: String?
  @Published var isLoading = false
  @Published var lastUpdate: Date?

  private let cacheManager = ContentCacheManager.shared
  private let cacheKey = "help_content_remote"
  private var cancellables = Set<AnyCancellable>()

  private init() {
    self.loadCachedContent()
    self.setupAutoRefresh()
  }

  private func setupAutoRefresh() {
    self.cacheManager.$isOfflineMode
      .filter { !$0 }
      .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        Task {
          await self?.refreshContent()
        }
      }
      .store(in: &self.cancellables)
  }

  private func loadCachedContent() {
    if let cachedHelp: String = cacheManager.cachedObject(for: cacheKey) {
      self.remoteHelpMarkdown = cachedHelp
      if let metadata = cacheManager.cacheMetadata(for: cacheKey),
        let timestamp = metadata["cachedAt"] as? TimeInterval {
        self.lastUpdate = Date(timeIntervalSince1970: timestamp)
      }
    }
  }

  func refreshContent() async {
    guard !self.isLoading else { return }

    self.isLoading = true
    defer { isLoading = false }

    do {
      guard let remoteURL = URL(string: "https://api.apgi-framework.org/help.md") else {
        logInfo("Invalid remote URL for help", context: "HelpManager.refreshContent")
        return
      }
      let data = try await cacheManager.fetchAndCache(from: remoteURL, cacheKey: self.cacheKey)
      if let markdown = String(data: data, encoding: .utf8) {
        await MainActor.run {
          self.remoteHelpMarkdown = markdown
          self.lastUpdate = Date()
        }
      }
    } catch {
      logWarning("Failed to refresh help content: \(error.localizedDescription)", context: "HelpContentManager")
    }
  }

  var currentHelpMarkdown: String {
    return remoteHelpMarkdown ?? canonicalHelpMarkdown
  }

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
        VStack(alignment: .leading, spacing: 4) {
          Text("Help & Documentation")
            .font(.title.bold())
          
          if let lastUpdate = helpManager.lastUpdate {
            Text("Last updated: \(lastUpdate.formatted(.relative(presentation: .named)))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        if helpManager.isLoading {
          ProgressView()
            .controlSize(.small)
            .padding(.trailing, 8)
        }

        Button {
          Task {
            await helpManager.refreshContent()
          }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .disabled(helpManager.isLoading)
        .help("Refresh help content")
      }
      .padding()
      .background(.thinMaterial)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          let content = self.helpManager.currentHelpMarkdown

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
    .task {
      if !ContentCacheManager.shared.isOfflineMode {
        await helpManager.refreshContent()
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
