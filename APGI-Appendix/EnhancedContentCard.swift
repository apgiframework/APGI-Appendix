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
  private init() {
  }

  /// Parse content string and extract tables from pipe-delimited format
  func parse(_ content: String) -> TableParseResult {
    var segments: [ContentSegment] = []
    let lines = content.components(separatedBy: "\n")

    var currentTextLines: [String] = []
    var tableLines: [String] = []
    var inTable = false
    var tableTitle: String?

    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Detect table row (contains | and has content on both sides)
      if self.isTableRow(trimmed) {
        if !inTable {
          // Starting a new table
          inTable = true

          // Check if previous non-empty line is a title
          if let lastTextLine = currentTextLines.last?.trimmingCharacters(in: .whitespaces),
            !lastTextLine.isEmpty,
            !lastTextLine.contains("|"),
            !currentTextLines.isEmpty {
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
    let headers = self.parseTableRow(headerLine)

    guard !headers.isEmpty else { return nil }

    // Remaining lines are data rows
    let rows = dataLines.map { self.parseTableRow($0) }

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
    let cleaned =
      trimmed
      .replacingOccurrences(of: ",", with: "")
      .replacingOccurrences(of: "%", with: "")
    return Double(cleaned)
  }

  private func columnKind(_ index: Int) -> ColumnKind {
    guard index < self.table.columnCount else { return .text }
    var numericCount = 0
    var sampleCount = 0
    for row in self.table.rows {
      guard index < row.count else { continue }
      let value = row[index].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      guard !value.isEmpty else { continue }
      sampleCount += 1
      if self.normalizedNumber(value) != nil { numericCount += 1 }
      if sampleCount >= 12 { break }
    }
    guard sampleCount > 0 else { return .text }
    return Double(numericCount) / Double(sampleCount) >= 0.7 ? .number : .text
  }

  private func cellAlignment(for columnIndex: Int) -> Alignment {
    switch self.columnKind(columnIndex) {
    case .number:
      return .trailing
    case .text:
      return .leading
    }
  }

  private var sortedRows: [[String]] {
    guard let column = sortColumn, column < table.columnCount else {
      return self.table.rows
    }

    let kind = self.columnKind(column)

    return self.table.rows.sorted { row1, row2 in
      let val1 = column < row1.count ? row1[column] : ""
      let val2 = column < row2.count ? row2[column] : ""

      switch kind {
      case .number:
        let num1 = self.normalizedNumber(val1)
        let num2 = self.normalizedNumber(val2)
        if let num1, let num2 {
          return self.sortAscending ? (num1 < num2) : (num1 > num2)
        }
        if num1 != nil, num2 == nil { return self.sortAscending }
        if num1 == nil, num2 != nil { return !self.sortAscending }
        let cmp = val1.localizedStandardCompare(val2)
        return self.sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
      case .text:
        let cmp = val1.localizedStandardCompare(val2)
        return self.sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
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
              ForEach(Array(self.sortedRows.enumerated()), id: \.offset) { index, row in
                self.dataRow(row, index: index)

                if index < self.sortedRows.count - 1 {
                  Divider()
                    .background(self.borderColor.opacity(0.5))
                }
              }
            } header: {
              VStack(spacing: 0) {
                self.headerRow
                Divider()
                  .background(self.borderColor)
              }
              .background(self.headerBackground)
            }
          }
          .padding(.bottom, 2)
        }
      }
      .frame(maxHeight: min(CGFloat(self.table.rowCount + 1) * 44 + 20, 520))
    }
    .background(self.backgroundColor)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(self.borderColor, lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
  }

  private var headerRow: some View {
    HStack(spacing: 0) {
      ForEach(Array(self.table.headers.enumerated()), id: \.offset) { index, header in
        Button {
          if self.sortColumn == index {
            self.sortAscending.toggle()
          } else {
            self.sortColumn = index
            self.sortAscending = true
          }
        } label: {
          HStack(spacing: 4) {
            Text(header)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.primary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)

            Spacer()

            if self.sortColumn == index {
              Image(
                systemName: self.sortAscending
                  ? SFSymbols.Navigation.up.symbol : SFSymbols.Navigation.down.symbol
              )
              .font(.system(size: 9, weight: .bold))
              .foregroundStyle(.secondary)
              .accessibilityLabel(self.sortAscending ? "Sorted ascending" : "Sorted descending")
            }
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .frame(minWidth: self.columnWidth(for: index), alignment: .leading)
        }
        .buttonStyle(.plain)

        if index < self.table.headers.count - 1 {
          Divider()
            .frame(height: 30)
            .background(self.borderColor.opacity(0.5))
        }
      }
    }
  }

  private func dataRow(_ row: [String], index: Int) -> some View {
    HStack(spacing: 0) {
      ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
        self.cellView(cell, columnIndex: colIndex)

        if colIndex < row.count - 1 {
          Divider()
            .background(self.borderColor.opacity(0.3))
        }
      }
    }
    .background(self.rowBackground(index: index))
    .contentShape(Rectangle())
    .onHover { hovering in
      self.hoveredRow = hovering ? index : nil
    }
    .onTapGesture {
      self.selectedRow = self.selectedRow == index ? nil : index
    }
  }

  private func cellView(_ content: String, columnIndex: Int) -> some View {
    // Parse special formatting
    let displayContent = self.parseSpecialContent(content)

    let isNumber = self.columnKind(columnIndex) == .number

    return HStack(spacing: 6) {
      if let icon = displayContent.icon {
        Image(systemName: icon)
          .font(.system(size: 11))
          .foregroundStyle(displayContent.iconColor ?? .secondary)
      }

      Text(displayContent.text)
        .font(
          isNumber ? .system(size: 13, weight: .regular, design: .monospaced) : .system(size: 13)
        )
        .foregroundStyle(displayContent.textColor ?? .primary)
        .lineLimit(nil)
        .multilineTextAlignment(isNumber ? .trailing : .leading)
        .textSelection(.enabled)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(
      minWidth: self.columnWidth(for: columnIndex), alignment: self.cellAlignment(for: columnIndex)
    )
    .contextMenu {
      Button("Copy") {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(displayContent.text, forType: .string)
      }
    }
  }

  private func columnWidth(for index: Int) -> CGFloat {
    // Calculate based on content
    let header = index < self.table.headers.count ? self.table.headers[index] : ""
    let maxContentLength = self.table.rows.reduce(header.count) {
      max($0, index < $1.count ? $1[index].count : 0)
    }

    // Min 80, max 300, scale with content
    let base = min(max(CGFloat(maxContentLength) * 7.5 + 28, 110), 380)
    return self.columnKind(index) == .number ? max(90, base * 0.9) : base
  }

  // MARK: - Styling

  private var backgroundColor: Color {
    if self.highContrastMode {
      return self.colorScheme == .dark ? Color.black : Color.white
    }
    return Color(NSColor.controlBackgroundColor)
  }

  private var headerBackground: Color {
    if self.highContrastMode {
      return self.colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
    }
    return Color.primary.opacity(0.05)
  }

  private var borderColor: Color {
    if self.highContrastMode {
      return self.colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    return Color.primary.opacity(0.1)
  }

  private func rowBackground(index: Int) -> Color {
    if self.selectedRow == index {
      return Color.accentColor.opacity(self.highContrastMode ? 0.25 : 0.15)
    }
    if self.hoveredRow == index {
      return Color.primary.opacity(self.highContrastMode ? 0.06 : 0.04)
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
    } else if text.lowercased().contains("well-supported")
      || text.lowercased().contains("plausible") {
      icon = "checkmark.circle"
      iconColor = .green
    } else if text.lowercased().contains("incomplete") || text.lowercased().contains("contested") {
      icon = "exclamationmark.triangle"
      iconColor = .orange
    }

    // Clean up arrows and special characters for display
    text =
      text
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
    SimpleTableParser.shared.parse(self.content).textSegments
  }

  var body: some View {
    LazyVStack(alignment: .leading, spacing: 16) {
      ForEach(self.segments) { segment in
        switch segment {
        case .text(let text):
          GlossaryHighlightedText(text: text, terms: self.terms)
            .font(.system(size: self.fontSize))
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
  @EnvironmentObject private var themeManager: ThemeManager
  @AppStorage("highContrastMode") private var highContrastMode = false
  @AppStorage("contentFontSize") private var fontSize: Double = 15.0

  @State private var isExpanded = true
  @State private var isFocusMode = false
  @State private var copyFeedback = false
  @FocusState private var isCardFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      self.cardHeader

      // Content
      if self.isExpanded {
        ScrollView {
          if self.hasDataTable {
            ParsedContentView(
              content: self.content,
              terms: GlossaryData.terms
            )
            .padding(APGISpacing.lg)
          } else {
            GlossaryHighlightedText(text: self.content, terms: GlossaryData.terms)
              .font(APGITypography.body)
              .textSelection(.enabled)
              .padding(APGISpacing.lg)
          }
        }
        .frame(maxHeight: 600)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .accessibilityLabel("Content of \(self.title)")
      }
    }
    .background(Color.darkNavy)
    .clipShape(RoundedRectangle(cornerRadius: APGIRadius.standard))
    .overlay(
      RoundedRectangle(cornerRadius: APGIRadius.standard)
        .strokeBorder(
          self.isCardFocused ? Color.thresholdBlue : self.borderColor,
          lineWidth: self.isCardFocused || self.highContrastMode ? 2 : 1
        )
    )
    .shadow(color: self.shadowColor, radius: self.highContrastMode ? 0 : 4, y: 2)
    .focusable()
    .focused(self.$isCardFocused)
    .accessibilityElement(children: .contain)
    .accessibilityLabel(self.title)
    .accessibilityHint(self.isExpanded ? "Double tap to collapse section" : "Double tap to expand section")
    .accessibilityAction {
        withAnimation(.spring(response: 0.3)) {
            self.isExpanded.toggle()
        }
    }
    .sheet(isPresented: self.$isFocusMode) {
      FocusModeView(isEnabled: self.$isFocusMode, content: self.content, title: self.title)
    }
  }

  private var cardHeader: some View {
    HStack(spacing: APGISpacing.md) {
      // Category indicator
      Circle()
        .fill(self.category.color)
        .frame(width: 8, height: 8)

      Text(self.title)
        .font(APGITypography.h3)
        .foregroundStyle(.primary)

      if self.hasDataTable {
        Image(systemName: SFSymbols.table)
          .font(APGITypography.micro)
          .foregroundStyle(.secondary)
          .accessibilityLabel("Table content")
      }

      Spacer()

      // Action buttons
      HStack(spacing: APGISpacing.sm) {
        Button {
          self.copyToClipboard()
        } label: {
          Image(systemName: self.copyFeedback ? SFSymbols.confirm : SFSymbols.copy)
            .font(APGITypography.micro)
            .foregroundStyle(self.copyFeedback ? .green : .secondary)
            .accessibilityLabel(self.copyFeedback ? "Copied" : "Copy")
        }
        .buttonStyle(.plain)
        .help("Copy content")

        Button {
          self.isFocusMode = true
        } label: {
          Image(systemName: SFSymbols.focusMode)
            .font(APGITypography.micro)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Focus mode")
        }
        .buttonStyle(.plain)
        .help("Focus mode")

        Button {
          withAnimation(.spring(response: 0.3)) {
            self.isExpanded.toggle()
          }
        } label: {
          Image(
            systemName: self.isExpanded
              ? SFSymbols.Navigation.up.symbol : SFSymbols.Navigation.down.symbol
          )
          .font(APGITypography.label.weight(.semibold))
          .foregroundStyle(.secondary)
          .accessibilityLabel(self.isExpanded ? "Collapse" : "Expand")
        }
        .buttonStyle(.plain)
        .help(self.isExpanded ? "Collapse" : "Expand")
      }
    }
    .padding(.horizontal, APGISpacing.md)
    .padding(.vertical, APGISpacing.md)
    .background(self.headerBackground)
  }

  private func copyToClipboard() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(self.content, forType: .string)

    withAnimation {
      self.copyFeedback = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation {
        self.copyFeedback = false
      }
    }
  }

  // MARK: - Styling

  private var cardBackground: Color {
    if self.highContrastMode {
      return self.colorScheme == .dark ? Color.black : Color.white
    }
    return Color(NSColor.controlBackgroundColor)
  }

  private var headerBackground: Color {
    self.category.color.opacity(self.highContrastMode ? 0.15 : 0.08)
  }

  private var borderColor: Color {
    if self.highContrastMode {
      return self.category.color
    }
    return Color.primary.opacity(0.1)
  }

  private var shadowColor: Color {
    self.highContrastMode ? .clear : .black.opacity(0.08)
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
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: APGISpacing.lg) {
          SectionHeroCard(
            title: self.section.title,
            keyTakeaway: self.section.summary,
            icon: self.section.icon,
            readingTime: self.section.estimatedReadingTime
          )

          if let diagram = section.conceptDiagram {
            InteractiveDiagram(diagram: diagram)
              .frame(height: 300)
          }

          ForEach(self.section.subsections) { subsection in
            CollapsibleSubsection(
              title: subsection.title,
              isExpanded: self.expandedSubsections.contains(subsection.id)
            ) {
              self.toggleExpanded(subsection.id)
            } content: {
              SubsectionContentCard(
                title: subsection.title,
                content: subsection.content,
                category: subsection.category,
                hasDataTable: subsection.hasDataTable
              )
            }
            .id(subsection.id)
          }

          if !self.section.relatedSections.isEmpty {
            RelatedSectionsCarousel(related: self.section.relatedSections)
          }
        }
        .padding()
      }
      .onReceive(NotificationCenter.default.publisher(for: .scrollToTables)) { notification in
        if let targetTab = notification.object as? Tab,
          targetTab.id == self.section.id
            || self.section.id.contains(targetTab.rawValue.lowercased()) {
          self.scrollToFirstTable(proxy: proxy)
        }
      }
    }
  }

  private func scrollToFirstTable(proxy: ScrollViewProxy) {
    if let firstTableSubsection = section.subsections.first(where: { $0.hasDataTable }) {
      withAnimation {
        self.expandedSubsections.insert(firstTableSubsection.id)
        proxy.scrollTo(firstTableSubsection.id, anchor: .top)
      }
    }
  }

  private func toggleExpanded(_ id: String) {
    if self.expandedSubsections.contains(id) {
      self.expandedSubsections.remove(id)
    } else {
      self.expandedSubsections.insert(id)
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
    VStack(alignment: .leading, spacing: APGISpacing.md) {
      HStack(alignment: .top, spacing: APGISpacing.md) {
        Image(systemName: self.icon)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.primary)
          .frame(width: 36, height: 36)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(Color.primary.opacity(self.colorScheme == .dark ? 0.18 : 0.06))
          )

        VStack(alignment: .leading, spacing: APGISpacing.xs) {
          Text(self.title)
            .font(APGITypography.h2)

          Text(self.readingTime)
            .font(APGITypography.micro)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }

      VStack(alignment: .leading, spacing: APGISpacing.sm) {
        Text("Key takeaway")
          .font(APGITypography.label)
          .foregroundStyle(.secondary)

        Text(self.keyTakeaway)
          .font(APGITypography.body)
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(APGISpacing.md)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.darkNavy)
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

      APGIConceptDiagram(source: self.diagram, contentMode: .fit)
        .scaleEffect(self.scale)
        .offset(self.offset)
        .gesture(
          DragGesture()
            .onChanged { value in
              self.offset = CGSize(
                width: self.lastOffset.width + value.translation.width,
                height: self.lastOffset.height + value.translation.height
              )
            }
            .onEnded { _ in
              self.lastOffset = self.offset
            }
        )
        .gesture(
          MagnificationGesture()
            .onChanged { value in
              self.scale = min(max(0.8, value), 3.0)
            }
        )

      VStack {
        HStack {
          Spacer()
          HStack(spacing: 8) {
            Button {
              self.scale = min(self.scale + 0.2, 3.0)
            } label: {
              Image(systemName: SFSymbols.zoomIn)
                .accessibilityLabel("Zoom in")
            }
            .buttonStyle(.borderless)

            Button {
              self.scale = max(self.scale - 0.2, 0.8)
            } label: {
              Image(systemName: SFSymbols.zoomOut)
                .accessibilityLabel("Zoom out")
            }
            .buttonStyle(.borderless)

            Button {
              self.scale = 1
              self.offset = .zero
              self.lastOffset = .zero
            } label: {
              Image(systemName: SFSymbols.replay)
                .accessibilityLabel("Reset zoom")
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
    VStack(alignment: .leading, spacing: APGISpacing.md) {
      Button(action: self.onToggle) {
        HStack(spacing: APGISpacing.md) {
          Image(systemName: SFSymbols.forward)
            .font(.caption.weight(.semibold))
            .rotationEffect(.degrees(self.isExpanded ? 90 : 0))
            .foregroundStyle(.secondary)
            .accessibilityLabel("Expand section")

          Text(self.title)
            .font(APGITypography.label)
            .foregroundStyle(.primary)

          Spacer()
        }
        .padding(.vertical, APGISpacing.md)
        .padding(.horizontal, APGISpacing.md)
        .background(
          RoundedRectangle(cornerRadius: APGIRadius.standard)
            .fill(Color.secondary.opacity(0.10))
        )
      }
      .buttonStyle(.plain)

      if self.isExpanded {
        self.content()
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

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: APGISpacing.md) {
        Circle()
          .fill(self.category.color)
          .frame(width: 8, height: 8)

        Text(self.title)
          .font(APGITypography.label)
          .foregroundStyle(.primary)

        Spacer()

        if self.hasDataTable {
          Image(systemName: SFSymbols.table)
            .font(APGITypography.micro)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Table content")
        }
      }
      .padding(.horizontal, APGISpacing.md)
      .padding(.vertical, APGISpacing.md)
      .background(self.category.color.opacity(0.06))

      if self.hasDataTable {
        ParsedContentView(content: self.content, terms: GlossaryData.terms)
          .padding(APGISpacing.md)
      } else {
        GlossaryHighlightedText(text: self.content, terms: GlossaryData.terms)
          .font(APGITypography.body)
          .textSelection(.enabled)
          .padding(APGISpacing.md)
      }
    }
    .background(Color.darkNavy)
    .clipShape(RoundedRectangle(cornerRadius: APGIRadius.standard))
    .overlay(
      RoundedRectangle(cornerRadius: APGIRadius.standard)
        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
    )
  }
}

struct RelatedSectionsCarousel: View {
  let related: [Tab]

  var body: some View {
    VStack(alignment: .leading, spacing: APGISpacing.md) {
      Text("Related")
        .font(APGITypography.label)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: APGISpacing.md) {
          ForEach(self.related, id: \.self) { tab in
            Button {
              NotificationCenter.default.post(name: .navigateToTab, object: tab)
            } label: {
              HStack(spacing: APGISpacing.sm) {
                Image(systemName: tab.icon)
                  .font(APGITypography.micro)
                  .foregroundStyle(tab.category.color)
                Text(tab.shortTitle)
                  .font(APGITypography.micro)
                  .foregroundStyle(.primary)
              }
              .padding(.horizontal, APGISpacing.md)
              .padding(.vertical, APGISpacing.md)
              .background(Color.darkNavy)
              .clipShape(RoundedRectangle(cornerRadius: APGIRadius.standard))
              .overlay(
                RoundedRectangle(cornerRadius: APGIRadius.standard)
                  .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.vertical, APGISpacing.xs)
      }
    }
    .padding(APGISpacing.md)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.secondary.opacity(0.06))
    )
  }
}
