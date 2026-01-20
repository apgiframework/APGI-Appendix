import SwiftUI

// MARK: - Progressive Content View
struct ProgressiveContentView: View {
    let sections: [ContentSection]
    @State private var visibleSectionCount = 5
    @State private var isLoadingMore = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Render visible sections
            ForEach(Array(sections.prefix(visibleSectionCount).enumerated()), id: \.element.id) { index, section in
                SectionContentView(section: section)
                    .id(section.id)
                
                // Show loading indicator at the end
                if index == visibleSectionCount - 1 && visibleSectionCount < sections.count {
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
                        loadMoreContent()
                    }
                }
            }
            
            // Load more button if needed
            if visibleSectionCount < sections.count && !isLoadingMore {
                Button("Load More (\(sections.count - visibleSectionCount) remaining)") {
                    loadMoreContent()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
    }
    
    private func loadMoreContent() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        // Simulate loading delay and load more content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            visibleSectionCount = min(visibleSectionCount + 5, sections.count)
            isLoadingMore = false
        }
    }
}

// MARK: - Virtualized Content View
struct VirtualizedContentView: View {
    let sections: [ContentSection]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sections) { section in
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
            Text(section.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .kerning(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyGlossaryHighlightedContent(text: section.content)
                .font(.system(size: fontSize, design: .default))
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
        max(1, (sections.count + itemsPerPage - 1) / itemsPerPage)
    }
    
    private var currentSections: [ContentSection] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, sections.count)
        return Array(sections[startIndex..<endIndex])
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Pagination controls
            if totalPages > 1 {
                HStack {
                    Button("Previous") {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Next") {
                        if currentPage < totalPages - 1 {
                            currentPage += 1
                        }
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            
            // Current page content
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(currentSections) { section in
                        SectionContentView(section: section)
                    }
                }
                .padding()
            }
            
            // Page size selector
            if sections.count > 10 {
                HStack {
                    Text("Items per page:")
                        .font(.caption)
                    
                    Picker("Items", selection: $itemsPerPage) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("50").tag(50)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: itemsPerPage) { _, _ in
                        currentPage = 0 // Reset to first page
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
            if sections.count <= 10 {
                // Small content - load all at once
                LazyVStack(spacing: 16) {
                    ForEach(sections) { section in
                        SectionContentView(section: section)
                    }
                }
                .padding()
            } else if sections.count <= 50 {
                // Medium content - progressive loading
                ProgressiveContentView(sections: sections)
            } else {
                // Large content - pagination
                PaginatedContentView(sections: sections)
            }
        }
    }
}
