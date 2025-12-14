import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    let onSelectTab: (Tab) -> Void

    @State private var searchText: String = ""
    @State private var searchResults: [SearchResult] = []

    struct SearchResult: Identifiable {
        let id = UUID()
        let tab: Tab
        let context: String
        let matchedText: String
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Search all content...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { _, _ in
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.bar)

            Divider()

            if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Try different keywords or check spelling")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchResults) { result in
                    Button {
                        onSelectTab(result.tab)
                        isPresented = false
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: result.tab.icon)
                                    .foregroundStyle(result.tab.category.color)

                                Text(result.tab.shortTitle)
                                    .font(.headline)
                            }

                            Text(highlightedText(result.context, query: result.matchedText))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 600, height: 500)
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        var results: [SearchResult] = []

        for tab in Tab.allCases {
            let haystack = tab.searchIndexText
            let lowerHaystack = haystack.lowercased()
            let lowerQuery = query.lowercased()

            var searchStartIndex = lowerHaystack.startIndex
            var matchesFound = 0

            while matchesFound < 3,
                  let range = lowerHaystack.range(of: lowerQuery, range: searchStartIndex..<lowerHaystack.endIndex) {
                let context = makeContextSnippet(from: haystack, matchRange: range)
                results.append(
                    SearchResult(
                        tab: tab,
                        context: context,
                        matchedText: String(haystack[range])
                    )
                )

                matchesFound += 1
                searchStartIndex = range.upperBound
            }
        }

        searchResults = results
    }

    private func makeContextSnippet(from text: String, matchRange: Range<String.Index>) -> String {
        let leadingCount = 60
        let trailingCount = 100

        let start = text.index(matchRange.lowerBound, offsetBy: -leadingCount, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(matchRange.upperBound, offsetBy: trailingCount, limitedBy: text.endIndex) ?? text.endIndex

        var snippet = String(text[start..<end])
        snippet = snippet.replacingOccurrences(of: "\n", with: " ")
        snippet = snippet.replacingOccurrences(of: "  ", with: " ")

        if start != text.startIndex {
            snippet = "…" + snippet
        }
        if end != text.endIndex {
            snippet = snippet + "…"
        }
        return snippet
    }

    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: query, options: [.caseInsensitive]) {
            attributed[range].backgroundColor = .yellow.opacity(0.35)
            attributed[range].foregroundColor = .primary
        }
        return attributed
    }
}

#Preview {
    SearchView(isPresented: .constant(true), onSelectTab: { _ in })
}
