import SwiftUI
import Combine

struct HelpView: View {
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
                    let content = getLocalHelpContent()

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

    private func getLocalHelpContent() -> String {
        return """
        # APGI Framework Help

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

        ## Getting Started

        The APGI Appendix provides comprehensive information about the Adaptive Precision-Gated Ignition Framework. Start with:

        1. **Methodology** - Understand the framework approach
        2. **Glossary** - Learn key terminology
        3. **Timeline** - Explore historical developments
        4. **Neuromodulators** - Study biological implementations

        ## Need More Help?

        Check the User Guide for detailed information about all features and navigation.
        """
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
                Text(section.title)
                    .font(.headline)

                Spacer()

                Text("Updated: \(section.lastUpdated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(section.content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .cornerRadius(8)
    }
}
