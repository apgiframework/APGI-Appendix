import SwiftUI

// MARK: - Content Segments

struct TableParseResult {
    let textSegments: [ContentSegment]
}

enum ContentSegment: Identifiable {
    case text(String)
    case table(ParsedTable)
    
    var id: String {
        switch self {
        case .text(let content): return "text-\(content.hashValue)"
        case .table(let table): return "table-\(table.id)"
        }
    }
}

// MARK: - Simple Table Parser Wrapper

final class SimpleTableParser {
    static let shared = SimpleTableParser()
    private init() {}
    
    /// Parse content string and extract tables from pipe-delimited format
    func parse(_ content: String) -> TableParseResult {
        var segments: [ContentSegment] = []
        let lines = content.components(separatedBy: "\n")
        
        var currentTextLines: [String] = []
        var tableLines: [String] = []
        var inTable = false
        var tableTitle: String?
        
        for (_, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect table row (contains | and has content on both sides)
            if isTableRow(trimmed) {
                if !inTable {
                    // Starting a new table
                    inTable = true
                    
                    // Check if previous non-empty line is a title
                    if let lastTextLine = currentTextLines.last?.trimmingCharacters(in: .whitespaces),
                       !lastTextLine.isEmpty,
                       !lastTextLine.contains("|"),
                       currentTextLines.count > 0 {
                        tableTitle = lastTextLine
                        currentTextLines.removeLast()
                    }
                    
                    // Flush accumulated text
                    if !currentTextLines.isEmpty {
                        let text = currentTextLines.joined(separator: "\n")
                        if !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                            segments.append(.text(text))
                        }
                        currentTextLines = []
                    }
                }
                tableLines.append(trimmed)
            } else {
                if inTable {
                    // End of table
                    if let table = parseTableLines(tableLines, title: tableTitle) {
                        segments.append(.table(table))
                    }
                    tableLines = []
                    tableTitle = nil
                    inTable = false
                }
                currentTextLines.append(line)
            }
        }
        
        // Handle remaining content
        if inTable && !tableLines.isEmpty {
            if let table = parseTableLines(tableLines, title: tableTitle) {
                segments.append(.table(table))
            }
        }
        
        if !currentTextLines.isEmpty {
            let text = currentTextLines.joined(separator: "\n")
            if !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                segments.append(.text(text))
            }
        }
        
        return TableParseResult(textSegments: segments)
    }
    
    private func isTableRow(_ line: String) -> Bool {
        guard line.contains("|") else { return false }
        let parts = line.split(separator: "|", omittingEmptySubsequences: false)
        return parts.count >= 2
    }
    
    private func parseTableLines(_ lines: [String], title: String?) -> ParsedTable? {
        guard !lines.isEmpty else { return nil }
        
        var dataLines = lines.filter { line in
            // Skip separator lines (e.g., |---|---|)
            let cleaned = line.replacingOccurrences(of: "-", with: "")
                             .replacingOccurrences(of: "|", with: "")
                             .replacingOccurrences(of: ":", with: "")
                             .trimmingCharacters(in: .whitespaces)
            return !cleaned.isEmpty
        }
        
        guard !dataLines.isEmpty else { return nil }
        
        // First line is headers
        let headerLine = dataLines.removeFirst()
        let headers = parseTableRow(headerLine)
        
        guard !headers.isEmpty else { return nil }
        
        // Remaining lines are data rows
        let rows = dataLines.map { parseTableRow($0) }
        
        // Normalize row lengths to match header count
        let normalizedRows = rows.map { row -> [String] in
            var normalized = row
            while normalized.count < headers.count {
                normalized.append("")
            }
            if normalized.count > headers.count {
                normalized = Array(normalized.prefix(headers.count))
            }
            return normalized
        }
        
        let metadata = TableMetadata(title: title)
        return ParsedTable(headers: headers, rows: normalizedRows, metadata: metadata)
    }
    
    private func parseTableRow(_ line: String) -> [String] {
        var row = line
        
        // Remove leading/trailing pipes
        if row.hasPrefix("|") { row.removeFirst() }
        if row.hasSuffix("|") { row.removeLast() }
        
        return row.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

struct APGITableView: View {
    let table: ParsedTable
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    @State private var sortColumn: Int?
    @State private var sortAscending = true
    @State private var hoveredRow: Int?
    @State private var selectedRow: Int?

    private enum ColumnKind {
        case number
        case text
    }

    private func normalizedNumber(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let cleaned = trimmed
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
        return Double(cleaned)
    }

    private func columnKind(_ index: Int) -> ColumnKind {
        guard index < table.columnCount else { return .text }
        var numericCount = 0
        var sampleCount = 0
        for row in table.rows {
            guard index < row.count else { continue }
            let v = row[index].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            guard !v.isEmpty else { continue }
            sampleCount += 1
            if normalizedNumber(v) != nil { numericCount += 1 }
            if sampleCount >= 12 { break }
        }
        guard sampleCount > 0 else { return .text }
        return Double(numericCount) / Double(sampleCount) >= 0.7 ? .number : .text
    }

    private func cellAlignment(for columnIndex: Int) -> Alignment {
        switch columnKind(columnIndex) {
        case .number:
            return .trailing
        case .text:
            return .leading
        }
    }

    private var sortedRows: [[String]] {
        guard let column = sortColumn, column < table.columnCount else {
            return table.rows
        }

        let kind = columnKind(column)

        return table.rows.sorted { row1, row2 in
            let val1 = column < row1.count ? row1[column] : ""
            let val2 = column < row2.count ? row2[column] : ""

            switch kind {
            case .number:
                let n1 = normalizedNumber(val1)
                let n2 = normalizedNumber(val2)
                if let n1, let n2 {
                    return sortAscending ? (n1 < n2) : (n1 > n2)
                }
                if n1 != nil, n2 == nil { return sortAscending }
                if n1 == nil, n2 != nil { return !sortAscending }
                let cmp = val1.localizedStandardCompare(val2)
                return sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
            case .text:
                let cmp = val1.localizedStandardCompare(val2)
                return sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table title
            if let title = table.title {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            ForEach(Array(sortedRows.enumerated()), id: \.offset) { index, row in
                                dataRow(row, index: index)

                                if index < sortedRows.count - 1 {
                                    Divider()
                                        .background(borderColor.opacity(0.5))
                                }
                            }
                        } header: {
                            VStack(spacing: 0) {
                                headerRow
                                Divider()
                                    .background(borderColor)
                            }
                            .background(headerBackground)
                        }
                    }
                    .padding(.bottom, 2)
                }
            }
            .frame(maxHeight: min(CGFloat(table.rowCount + 1) * 44 + 20, 520))
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(table.headers.enumerated()), id: \.offset) { index, header in
                Button {
                    if sortColumn == index {
                        sortAscending.toggle()
                    } else {
                        sortColumn = index
                        sortAscending = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(header)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if sortColumn == index {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minWidth: columnWidth(for: index), alignment: .leading)
                }
                .buttonStyle(.plain)
                
                if index < table.headers.count - 1 {
                    Divider()
                        .frame(height: 30)
                        .background(borderColor.opacity(0.5))
                }
            }
        }
    }
    
    private func dataRow(_ row: [String], index: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                cellView(cell, columnIndex: colIndex)
                
                if colIndex < row.count - 1 {
                    Divider()
                        .background(borderColor.opacity(0.3))
                }
            }
        }
        .background(rowBackground(index: index))
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredRow = hovering ? index : nil
        }
        .onTapGesture {
            selectedRow = selectedRow == index ? nil : index
        }
    }
    
    private func cellView(_ content: String, columnIndex: Int) -> some View {
        // Parse special formatting
        let displayContent = parseSpecialContent(content)

        let isNumber = columnKind(columnIndex) == .number

        return HStack(spacing: 6) {
            if let icon = displayContent.icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(displayContent.iconColor ?? .secondary)
            }

            Text(displayContent.text)
                .font(isNumber ? .system(size: 13, weight: .regular, design: .monospaced) : .system(size: 13))
                .foregroundStyle(displayContent.textColor ?? .primary)
                .lineLimit(nil)
                .multilineTextAlignment(isNumber ? .trailing : .leading)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: columnWidth(for: columnIndex), alignment: cellAlignment(for: columnIndex))
        .contextMenu {
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(displayContent.text, forType: .string)
            }
        }
    }
    
    private func columnWidth(for index: Int) -> CGFloat {
        // Calculate based on content
        let header = index < table.headers.count ? table.headers[index] : ""
        let maxContentLength = table.rows.reduce(header.count) { max($0, index < $1.count ? $1[index].count : 0) }
        
        // Min 80, max 300, scale with content
        let base = min(max(CGFloat(maxContentLength) * 7.5 + 28, 110), 380)
        return columnKind(index) == .number ? max(90, base * 0.9) : base
    }
    
    // MARK: - Styling
    
    private var backgroundColor: Color {
        if highContrastMode {
            return colorScheme == .dark ? Color.black : Color.white
        }
        return Color(NSColor.controlBackgroundColor)
    }
    
    private var headerBackground: Color {
        if highContrastMode {
            return colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
        }
        return Color.primary.opacity(0.05)
    }
    
    private var borderColor: Color {
        if highContrastMode {
            return colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
        }
        return Color.primary.opacity(0.1)
    }
    
    private func rowBackground(index: Int) -> Color {
        if selectedRow == index {
            return Color.accentColor.opacity(highContrastMode ? 0.25 : 0.15)
        }
        if hoveredRow == index {
            return Color.primary.opacity(highContrastMode ? 0.06 : 0.04)
        }
        return index % 2 == 0 ? Color.clear : Color.primary.opacity(0.02)
    }
    
    // MARK: - Content Parsing
    
    private struct DisplayContent {
        let text: String
        let icon: String?
        let iconColor: Color?
        let textColor: Color?
    }
    
    private func parseSpecialContent(_ content: String) -> DisplayContent {
        var text = content
        var icon: String?
        var iconColor: Color?
        var textColor: Color?
        
        // Check for status indicators
        if text.contains("↑") || text.lowercased().contains("increase") {
            icon = "arrow.up"
            iconColor = .green
        } else if text.contains("↓") || text.lowercased().contains("decrease") {
            icon = "arrow.down"
            iconColor = .red
        } else if text.lowercased().contains("not done") || text.lowercased().contains("unsupported") {
            icon = "xmark.circle"
            iconColor = .red
            textColor = .secondary
        } else if text.lowercased().contains("well-supported") || text.lowercased().contains("plausible") {
            icon = "checkmark.circle"
            iconColor = .green
        } else if text.lowercased().contains("incomplete") || text.lowercased().contains("contested") {
            icon = "exclamationmark.triangle"
            iconColor = .orange
        }
        
        // Clean up arrows and special characters for display
        text = text
            .replacingOccurrences(of: "→", with: "→ ")
            .replacingOccurrences(of: "——", with: "—")
        
        return DisplayContent(text: text, icon: icon, iconColor: iconColor, textColor: textColor)
    }
}

// MARK: - Content View with Table Support

struct ParsedContentView: View {
    let content: String
    let terms: [String]
    
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    
    private var segments: [ContentSegment] {
        SimpleTableParser.shared.parse(content).textSegments
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(segments) { segment in
                switch segment {
                case .text(let text):
                    GlossaryHighlightedText(text: text, terms: terms)
                        .font(.system(size: fontSize))
                        .textSelection(.enabled)
                    
                case .table(let table):
                    APGITableView(table: table)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Enhanced Content Card with Table Parsing

struct EnhancedContentCard: View {
    let title: String
    let content: String
    let category: SectionCategory
    let hasDataTable: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("highContrastMode") private var highContrastMode = false
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    
    @State private var isExpanded = true
    @State private var isFocusMode = false
    @State private var copyFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            cardHeader
            
            // Content
            if isExpanded {
                ScrollView {
                    if hasDataTable {
                        ParsedContentView(
                            content: content,
                            terms: GlossaryData.terms
                        )
                        .padding(20)
                    } else {
                        GlossaryHighlightedText(text: content, terms: GlossaryData.terms)
                            .font(.system(size: fontSize))
                            .textSelection(.enabled)
                            .padding(20)
                    }
                }
                .frame(maxHeight: 600)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: highContrastMode ? 2 : 1)
        )
        .shadow(color: shadowColor, radius: highContrastMode ? 0 : 4, y: 2)
        .sheet(isPresented: $isFocusMode) {
            FocusModeView(isEnabled: $isFocusMode, content: content, title: title)
        }
    }
    
    private var cardHeader: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            
            if hasDataTable {
                Image(systemName: "tablecells")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button {
                    copyToClipboard()
                } label: {
                    Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(copyFeedback ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy content")
                
                Button {
                    isFocusMode = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Focus mode")
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "Collapse" : "Expand")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(headerBackground)
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        
        withAnimation {
            copyFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copyFeedback = false
            }
        }
    }
    
    // MARK: - Styling
    
    private var cardBackground: Color {
        if highContrastMode {
            return colorScheme == .dark ? Color.black : Color.white
        }
        return Color(NSColor.controlBackgroundColor)
    }
    
    private var headerBackground: Color {
        category.color.opacity(highContrastMode ? 0.15 : 0.08)
    }
    
    private var borderColor: Color {
        if highContrastMode {
            return category.color
        }
        return Color.primary.opacity(0.1)
    }
    
    private var shadowColor: Color {
        highContrastMode ? .clear : .black.opacity(0.08)
    }
}

struct EnhancedSection: Identifiable {
    struct Subsection: Identifiable {
        let id: String
        let title: String
        let content: String
        let category: SectionCategory
        let hasDataTable: Bool
    }

    let id: String
    let title: String
    let summary: String
    let icon: String
    let estimatedReadingTime: String
    let conceptDiagram: APGIDiagramSource?
    let subsections: [Subsection]
    let relatedSections: [Tab]
}

struct EnhancedSectionView: View {
    let section: EnhancedSection
    @State private var expandedSubsections: Set<String> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: APGISpacing.lg) {
                SectionHeroCard(
                    title: section.title,
                    keyTakeaway: section.summary,
                    icon: section.icon,
                    readingTime: section.estimatedReadingTime
                )

                if let diagram = section.conceptDiagram {
                    InteractiveDiagram(diagram: diagram)
                        .frame(height: 300)
                }

                ForEach(section.subsections) { subsection in
                    CollapsibleSubsection(
                        title: subsection.title,
                        isExpanded: expandedSubsections.contains(subsection.id)
                    ) {
                        toggleExpanded(subsection.id)
                    } content: {
                        SubsectionContentCard(
                            title: subsection.title,
                            content: subsection.content,
                            category: subsection.category,
                            hasDataTable: subsection.hasDataTable
                        )
                    }
                }

                if !section.relatedSections.isEmpty {
                    RelatedSectionsCarousel(related: section.relatedSections)
                }
            }
            .padding()
        }
    }

    private func toggleExpanded(_ id: String) {
        if expandedSubsections.contains(id) {
            expandedSubsections.remove(id)
        } else {
            expandedSubsections.insert(id)
        }
    }
}

struct SectionHeroCard: View {
    let title: String
    let keyTakeaway: String
    let icon: String
    let readingTime: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.06))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(APGITypography.titleLarge)
                        .fontWeight(.bold)

                    Text(readingTime)
                        .font(APGITypography.labelSmall)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Key takeaway")
                    .font(APGITypography.labelMedium)
                    .foregroundStyle(.secondary)

                Text(keyTakeaway)
                    .font(APGITypography.bodyLarge)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct InteractiveDiagram: View {
    let diagram: APGIDiagramSource

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))

            APGIConceptDiagram(source: diagram, contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(0.8, value), 3.0)
                        }
                )

            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            scale = min(scale + 0.2, 3.0)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            scale = max(scale - 0.2, 0.8)
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            scale = 1
                            offset = .zero
                            lastOffset = .zero
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(10)
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct CollapsibleSubsection<Content: View>: View {
    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)

                    Text(title)
                        .font(APGITypography.labelLarge)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct SubsectionContentCard: View {
    let title: String
    let content: String
    let category: SectionCategory
    let hasDataTable: Bool

    @AppStorage("contentFontSize") private var fontSize: Double = 15.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(APGITypography.labelLarge)
                    .foregroundStyle(.primary)

                Spacer()

                if hasDataTable {
                    Image(systemName: "tablecells")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(category.color.opacity(0.06))

            if hasDataTable {
                ParsedContentView(content: content, terms: GlossaryData.terms)
                    .padding(16)
            } else {
                GlossaryHighlightedText(text: content, terms: GlossaryData.terms)
                    .font(.system(size: fontSize))
                    .textSelection(.enabled)
                    .padding(16)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct RelatedSectionsCarousel: View {
    let related: [Tab]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Related")
                .font(APGITypography.labelLarge)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(related, id: \.self) { tab in
                        Button {
                            NotificationCenter.default.post(name: .navigateToTab, object: tab)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(tab.category.color)
                                Text(tab.shortTitle)
                                    .font(APGITypography.labelMedium)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}
