import SwiftUI

// MARK: - Progressive Content View

struct ProgressiveContentView: View {
    let sections: [ContentSection]
    @State private var visibleSectionCount = 5
    @State private var isLoadingMore = false

    var body: some View {
        VStack(spacing: 0) {
            // Render visible sections
            ForEach(Array(self.sections.prefix(self.visibleSectionCount).enumerated()), id: \.element.id) { index, section in
                SectionContentView(section: section)
                    .id(section.id)

                // Show loading indicator at the end
                if index == self.visibleSectionCount - 1 && self.visibleSectionCount < self.sections.count {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .onAppear {
                        self.loadMoreContent()
                    }
                }
            }

            // Load more button if needed
            if self.visibleSectionCount < self.sections.count && !self.isLoadingMore {
                Button("Load More (\(self.sections.count - self.visibleSectionCount) remaining)") {
                    self.loadMoreContent()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }

    private func loadMoreContent() {
        guard !self.isLoadingMore else { return }

        self.isLoadingMore = true

        // Simulate loading delay and load more content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.visibleSectionCount = min(self.visibleSectionCount + 5, self.sections.count)
            self.isLoadingMore = false
        }
    }
}

// MARK: - Virtualized Content View

struct VirtualizedContentView: View {
    let sections: [ContentSection]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(self.sections) { section in
                    SectionContentView(section: section)
                        .id(section.id)
                }
            }
            .padding()
        }
    }
}

// MARK: - Section Content View

struct SectionContentView: View {
    let section: ContentSection
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(self.section.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .kerning(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyGlossaryHighlightedContent(text: self.section.content)
                .font(.system(size: self.fontSize, design: .default))
                .lineSpacing(6)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(APGISpacing.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                .fill(.background)
                .shadow(color: Color.apgiPurple.opacity(0.06), radius: 10, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: APGIRadius.lg, style: .continuous)
                .strokeBorder(Color.apgiPurple.opacity(0.16), lineWidth: 1)
        }
    }
}

// MARK: - Content Section Model

struct ContentSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

// MARK: - Paginated Content View

struct PaginatedContentView: View {
    let sections: [ContentSection]
    @State private var currentPage = 0
    @State private var itemsPerPage = 10

    private var totalPages: Int {
        max(1, (self.sections.count + self.itemsPerPage - 1) / self.itemsPerPage)
    }

    private var currentSections: [ContentSection] {
        let startIndex = self.currentPage * self.itemsPerPage
        let endIndex = min(startIndex + self.itemsPerPage, self.sections.count)
        return Array(self.sections[startIndex ..< endIndex])
    }

    var body: some View {
        VStack(spacing: 16) {
            // Pagination controls
            if self.totalPages > 1 {
                HStack {
                    Button("Previous") {
                        if self.currentPage > 0 {
                            self.currentPage -= 1
                        }
                    }
                    .disabled(self.currentPage == 0)

                    Spacer()

                    Text("Page \(self.currentPage + 1) of \(self.totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Next") {
                        if self.currentPage < self.totalPages - 1 {
                            self.currentPage += 1
                        }
                    }
                    .disabled(self.currentPage >= self.totalPages - 1)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }

            // Current page content
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(self.currentSections) { section in
                        SectionContentView(section: section)
                    }
                }
                .padding()
            }

            // Page size selector
            if self.sections.count > 10 {
                HStack {
                    Text("Items per page:")
                        .font(.caption)

                    Picker("Items", selection: self.$itemsPerPage) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: self.itemsPerPage) { _, _ in
                        self.currentPage = 0 // Reset to first page
                    }
                }
                .font(.caption)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Smart Content View (chooses best loading strategy)

struct SmartContentView: View {
    let sections: [ContentSection]

    var body: some View {
        Group {
            if self.sections.count <= 10 {
                // Small content - load all at once
                LazyVStack(spacing: 16) {
                    ForEach(self.sections) { section in
                        SectionContentView(section: section)
                    }
                }
                .padding()
            }
            else if self.sections.count <= 50 {
                // Medium content - progressive loading
                ProgressiveContentView(sections: self.sections)
            }
            else {
                // Large content - pagination
                PaginatedContentView(sections: self.sections)
            }
        }
    }
}
