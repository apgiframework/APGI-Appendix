import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    let onSelectTab: (Tab) -> Void

    @State private var searchText: String = ""
    @State private var selectedFilters: Set<SectionCategory> = []
    @State private var searchResults: [SearchResult] = []
    @State private var searchScope: SearchScope = .all

    enum SearchScope: Hashable {
        case all, titles, content, formulas, references, glossary
    }

    struct SearchResult: Identifiable {
        let id = UUID()
        let title: String
        let excerpt: AttributedString
        let category: SectionCategory
        let section: Tab
        let relevance: Double
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Search framework...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { _, _ in
                        performSearch()
                    }

                Menu {
                    Picker("Scope", selection: $searchScope) {
                        Text("All").tag(SearchScope.all)
                        Text("Titles Only").tag(SearchScope.titles)
                        Text("Content").tag(SearchScope.content)
                        Text("Formulas").tag(SearchScope.formulas)
                        Text("References").tag(SearchScope.references)
                        Text("Glossary Terms").tag(SearchScope.glossary)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .onChange(of: searchScope) { _, _ in
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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SectionCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedFilters.contains(category),
                            tint: category.color
                        ) {
                            toggleFilter(category)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            Divider()

            if searchResults.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    SearchResultRow(result: result)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectTab(result.section)
                            isPresented = false
                        }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 720, height: 560)
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let effectiveTabs: [Tab] = {
            switch searchScope {
            case .references:
                return [.bibliography]
            case .glossary:
                return []
            default:
                return Tab.allCases
            }
        }()

        let allowedCategories: Set<SectionCategory> = selectedFilters

        var results: [SearchResult] = []

        for tab in effectiveTabs {
            if !allowedCategories.isEmpty, !allowedCategories.contains(tab.category) {
                continue
            }

            let (titleHaystack, contentHaystack) = searchableText(for: tab)
            let candidates = matchingCandidates(title: titleHaystack, content: contentHaystack, query: query)
            results.append(contentsOf: candidates)
        }

        if searchScope == .glossary || searchScope == .all {
            let glossaryMatches = searchGlossary(query: query)
            let filteredGlossaryMatches: [SearchResult]
            if allowedCategories.isEmpty {
                filteredGlossaryMatches = glossaryMatches
            } else {
                filteredGlossaryMatches = glossaryMatches.filter { allowedCategories.contains($0.category) }
            }
            results.append(contentsOf: filteredGlossaryMatches)
        }

        searchResults = results.sorted { lhs, rhs in
            if lhs.relevance != rhs.relevance {
                return lhs.relevance > rhs.relevance
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func toggleFilter(_ category: SectionCategory) {
        if selectedFilters.contains(category) {
            selectedFilters.remove(category)
        } else {
            selectedFilters.insert(category)
        }
        performSearch()
    }

    private func searchableText(for tab: Tab) -> (title: String, content: String) {
        let title = tab.rawValue
        let content = tab.searchIndexText
        return (title, content)
    }

    private func matchingCandidates(title: String, content: String, query: String) -> [SearchResult] {
        let lowerQuery = query.lowercased()
        let titleLower = title.lowercased()
        let contentLower = content.lowercased()

        let titleMatches = titleLower.components(separatedBy: lowerQuery).count - 1
        let contentMatches = contentLower.components(separatedBy: lowerQuery).count - 1

        let shouldSearchTitles: Bool = (searchScope == .all || searchScope == .titles)
        let shouldSearchContent: Bool = (searchScope == .all || searchScope == .content || searchScope == .formulas || searchScope == .references)

        let matchedInTitle = shouldSearchTitles && titleMatches > 0
        let matchedInContent = shouldSearchContent && contentMatches > 0

        guard matchedInTitle || matchedInContent else {
            return []
        }

        var results: [SearchResult] = []

        if matchedInTitle {
            let excerpt = makeHighlightedExcerpt(from: title, query: query)
            results.append(
                SearchResult(
                    title: title,
                    excerpt: excerpt,
                    category: tabForTitle(title).category,
                    section: tabForTitle(title),
                    relevance: 10_000 + Double(titleMatches) * 100
                )
            )
        }

        if matchedInContent {
            let sectionTab = tabForTitle(title)
            let snippet = makeContextSnippet(from: content, query: query)
            let excerpt = makeHighlightedExcerpt(from: snippet, query: query)
            results.append(
                SearchResult(
                    title: sectionTab.shortTitle,
                    excerpt: excerpt,
                    category: sectionTab.category,
                    section: sectionTab,
                    relevance: Double(contentMatches) * 10
                )
            )
        }

        return results
    }

    private func tabForTitle(_ title: String) -> Tab {
        Tab.allCases.first(where: { $0.rawValue == title }) ?? .methodology
    }

    private func makeContextSnippet(from text: String, query: String) -> String {
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()
        guard let range = lowerText.range(of: lowerQuery) else {
            return String(text.prefix(160))
        }

        let leadingCount = 60
        let trailingCount = 100

        let start = text.index(range.lowerBound, offsetBy: -leadingCount, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: trailingCount, limitedBy: text.endIndex) ?? text.endIndex

        var snippet = String(text[start..<end])
        snippet = snippet.replacingOccurrences(of: "\n", with: " ")
        while snippet.contains("  ") {
            snippet = snippet.replacingOccurrences(of: "  ", with: " ")
        }

        if start != text.startIndex {
            snippet = "…" + snippet
        }
        if end != text.endIndex {
            snippet = snippet + "…"
        }

        return snippet
    }

    private func makeHighlightedExcerpt(from text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)

        if let foundRange = attributed.range(of: query, options: [.caseInsensitive]) {
            attributed[foundRange].backgroundColor = .yellow.opacity(0.35)
            attributed[foundRange].foregroundColor = .primary
        }

        return attributed
    }

    private func searchGlossary(query: String) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lowerQuery = trimmed.lowercased()

        let matches = GlossaryData.entries.filter { entry in
            entry.term.lowercased().contains(lowerQuery) || entry.definition.lowercased().contains(lowerQuery)
        }

        return matches.map { entry in
            let snippet = makeContextSnippet(from: entry.definition, query: trimmed)
            let excerpt = makeHighlightedExcerpt(from: "\(entry.term): \(snippet)", query: trimmed)
            return SearchResult(
                title: entry.term,
                excerpt: excerpt,
                category: .reference,
                section: .glossary,
                relevance: entry.term.lowercased().contains(lowerQuery) ? 500 : 100
            )
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    Capsule()
                        .fill(isSelected ? tint : Color.secondary.opacity(0.15))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct SearchResultRow: View {
    let result: SearchView.SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: result.section.icon)
                    .foregroundStyle(result.category.color)

                Text(result.title)
                    .font(.headline)

                Spacer()

                Text(result.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(result.excerpt)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SearchView(isPresented: .constant(true), onSelectTab: { _ in })
}
