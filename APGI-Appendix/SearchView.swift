import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    let onSelectTab: (Tab) -> Void

    @State private var searchText: String = ""
    @State private var selectedFilters: Set<SectionCategory> = []
    @State private var searchResults: [SearchResult] = []
    @State private var searchScope: SearchScope = .all
    @State private var isSearching = false
    @State private var searchError: String?

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
                    .onChange(of: searchText) { _, newValue in
                        Task {
                            try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                            if newValue == searchText { // Only search if text hasn't changed
                                performSearch()
                            }
                        }
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

            if isSearching {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Searching...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let searchError = searchError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Search Error")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(searchError)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        performSearch()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if searchResults.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: searchResults.count)
            }
        }
        .frame(width: 720, height: 560)
    }

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }

        isSearching = true
        searchError = nil

        Task {
            do {
                let results = try await performAsyncSearch(query: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                    self.searchError = nil
                }
            } catch {
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                    self.searchError = error.localizedDescription
                }
            }
        }
    }
    
    private func performAsyncSearch(query: String) async throws -> [SearchResult] {
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

        return results.sorted { lhs, rhs in
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
        let shouldSearchContent: Bool = (searchScope == .all || searchScope == .content)
        let shouldSearchFormulas: Bool = (searchScope == .all || searchScope == .formulas)
        let shouldSearchReferences: Bool = (searchScope == .all || searchScope == .references)

        let matchedInTitle = shouldSearchTitles && titleMatches > 0
        let matchedInContent = shouldSearchContent && contentMatches > 0
        let matchedInFormulas = shouldSearchFormulas && containsFormulas(content: content, query: lowerQuery)
        let matchedInReferences = shouldSearchReferences && containsReferences(content: content, query: lowerQuery)

        guard matchedInTitle || matchedInContent || matchedInFormulas || matchedInReferences else {
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

        if matchedInContent || matchedInFormulas || matchedInReferences {
            let sectionTab = tabForTitle(title)
            let snippet = makeContextSnippet(from: content, query: query)
            let excerpt = makeHighlightedExcerpt(from: snippet, query: query)
            
            var relevanceScore = Double(contentMatches) * 10
            if matchedInFormulas {
                relevanceScore += 500
            }
            if matchedInReferences {
                relevanceScore += 300
            }
            
            results.append(
                SearchResult(
                    title: sectionTab.shortTitle,
                    excerpt: excerpt,
                    category: sectionTab.category,
                    section: sectionTab,
                    relevance: relevanceScore
                )
            )
        }

        return results
    }
    
    private func containsFormulas(content: String, query: String) -> Bool {
        let formulaPatterns = [
            "\\$[^$]+\\$",  // LaTeX math mode
            "\\[[^\\]]+\\]", // Bracket formulas
            "α|β|γ|δ|ε|ζ|η|θ|λ|μ|π|σ|τ|φ|χ|ψ|ω", // Greek letters
            "\\b[A-Z][a-z]*\\([a-zA-Z,\\s]*\\)", // Function notation
            "\\b\\d+\\.?\\d*\\s*[×÷±=<>≤≥]\\s*\\d+\\.?\\d*" // Mathematical expressions
        ]
        
        for pattern in formulaPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            if let matches = matches, !matches.isEmpty {
                let formulaContent = matches.map { String(content[Range($0.range, in: content)!]) }.joined(separator: " ")
                return formulaContent.lowercased().contains(query)
            }
        }
        
        return false
    }
    
    private func containsReferences(content: String, query: String) -> Bool {
        let referencePatterns = [
            "\\(\\d{4}\\)", // Year references
            "\\[[^\\]]+\\d{4}[^\\]]*\\]", // Bracketed references with years
            "\\b[A-Z][a-z]+\\s+et\\s+al\\.", // "et al." citations
            "\\bdoi:\\s*10\\.\\d+", // DOI references
            "\\bISBN\\s*[:\\s-]*\\d", // ISBN references
            "\\bFig\\.\\s*\\d+", // Figure references
            "\\bTable\\s*\\d+", // Table references
            "\\bChapter\\s*\\d+", // Chapter references
            "\\bSection\\s*\\d+", // Section references
            "\\bPage\\s*\\d+" // Page references
        ]
        
        for pattern in referencePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let matches = regex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            if let matches = matches, !matches.isEmpty {
                let referenceContent = matches.map { String(content[Range($0.range, in: content)!]) }.joined(separator: " ")
                return referenceContent.lowercased().contains(query)
            }
        }
        
        return false
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
    
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    Capsule()
                        .fill(isSelected ? tint : Color.secondary.opacity(isHovered ? 0.25 : 0.15))
                }
                .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct SearchResultRow: View {
    let result: SearchView.SearchResult
    @State private var isHovered = false

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
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

#Preview {
    SearchView(isPresented: .constant(true), onSelectTab: { _ in })
}
