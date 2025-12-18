import SwiftUI

// MARK: - Table Data Models

struct ParsedTable: Identifiable, Equatable {
    let id = UUID()
    let headers: [String]
    let rows: [[String]]
    let title: String?
    
    var columnCount: Int { headers.count }
    var rowCount: Int { rows.count }
}

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

// MARK: - Table Parser

final class TableParser {
    
    static let shared = TableParser()
    
    private init() {}
    
    /// Parse content string and extract tables from pipe-delimited format
    func parse(_ content: String) -> TableParseResult {
        var segments: [ContentSegment] = []
        let lines = content.components(separatedBy: "\n")
        
        var currentTextLines: [String] = []
        var tableLines: [String] = []
        var inTable = false
        var tableTitle: String?
        
        for (index, line) in lines.enumerated() {
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
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
        
        return ParsedTable(headers: headers, rows: normalizedRows, title: title)
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

// MARK: - Table View Components

struct APGITableView: View {
    let table: ParsedTable
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    @State private var sortColumn: Int?
    @State private var sortAscending = true
    @State private var hoveredRow: Int?
    @State private var selectedRow: Int?
    
    private var sortedRows: [[String]] {
        guard let column = sortColumn, column < table.columnCount else {
            return table.rows
        }
        
        return table.rows.sorted { row1, row2 in
            let val1 = column < row1.count ? row1[column] : ""
            let val2 = column < row2.count ? row2[column] : ""
            return sortAscending ? val1 < val2 : val1 > val2
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
            
            // Scrollable table
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    headerRow
                    
                    Divider()
                        .background(borderColor)
                    
                    // Data rows
                    ForEach(Array(sortedRows.enumerated()), id: \.offset) { index, row in
                        dataRow(row, index: index)
                        
                        if index < sortedRows.count - 1 {
                            Divider()
                                .background(borderColor.opacity(0.5))
                        }
                    }
                }
            }
            .frame(maxHeight: min(CGFloat(table.rowCount + 1) * 44 + 20, 500))
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
                    .background(headerBackground)
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
        
        return HStack(spacing: 4) {
            if let icon = displayContent.icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(displayContent.iconColor ?? .secondary)
            }
            
            Text(displayContent.text)
                .font(.system(size: 13))
                .foregroundStyle(displayContent.textColor ?? .primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minWidth: columnWidth(for: columnIndex), alignment: .leading)
    }
    
    private func columnWidth(for index: Int) -> CGFloat {
        // Calculate based on content
        let header = index < table.headers.count ? table.headers[index] : ""
        let maxContentLength = table.rows.reduce(header.count) { max($0, index < $1.count ? $1[index].count : 0) }
        
        // Min 80, max 300, scale with content
        return min(max(CGFloat(maxContentLength) * 8 + 24, 100), 350)
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
            return Color.accentColor.opacity(0.15)
        }
        if hoveredRow == index {
            return Color.primary.opacity(0.03)
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
        TableParser.shared.parse(content).textSegments
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
