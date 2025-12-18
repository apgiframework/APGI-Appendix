import SwiftUI

struct EnhancedContentCard: View {
    let title: String
    let content: String
    let category: SectionCategory
    let hasDataTable: Bool

    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    @State private var isFocusModeEnabled: Bool = false
    @State private var scrollProgress: Double = 0
    @State private var isTableExpanded: Bool = true

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(category.color.gradient)
                        .frame(width: 40, height: 40)
                        .background(category.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .kerning(0.5)

                            if hasDataTable {
                                Text("📊")
                                    .font(.caption)
                            }
                        }

                        Text(title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }

                HStack(spacing: 12) {
                    ReadingProgressView(progress: scrollProgress, estimatedTime: estimatedReadingTimeMinutes)

                    Spacer(minLength: 8)

                    FontSizeControl()

                    Button {
                        isFocusModeEnabled = true
                    } label: {
                        Image(systemName: "rectangle.inset.filled.and.person.filled")
                    }
                    .buttonStyle(.borderless)
                    .apgiAccessibility(
                        label: "Focus mode",
                        hint: "Open a distraction-free reading view",
                        traits: .isButton
                    )
                    .keyboardShortcut("f", modifiers: [.command])
                }

                Divider()
                    .background(category.color.opacity(0.3))

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("EnhancedContentCardScroll")).minY)
                        }
                        .frame(height: 0)

                        if hasDataTable, let parsedTable {
                            DisclosureGroup(isExpanded: $isTableExpanded) {
                                EnhancedDataTable(
                                    columns: parsedTable.columns,
                                    rows: parsedTable.rows
                                )
                                .padding(.top, 8)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "tablecells")
                                        .foregroundStyle(category.color)

                                    Text("Table")
                                        .font(.system(size: 15, weight: .semibold))

                                    Text("(derived from the text below)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(category.color.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(category.color.opacity(0.18), lineWidth: 1)
                            )
                            .padding(.bottom, 16)
                        }

                        LazyGlossaryHighlightedContent(text: content)
                            .font(.system(size: fontSize, design: .default))
                            .lineSpacing(6)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
                                }
                            )
                    }
                    .padding(.vertical, 2)
                }
                .coordinateSpace(name: "EnhancedContentCardScroll")
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ScrollViewportPreferenceKey.self, value: proxy.size.height)
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    scrollState.offset = offset
                    updateScrollProgress()
                }
                .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                    scrollState.contentHeight = height
                    updateScrollProgress()
                }
                .onPreferenceChange(ScrollViewportPreferenceKey.self) { height in
                    scrollState.viewportHeight = height
                    updateScrollProgress()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(color: category.color.opacity(0.1), radius: 8, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [category.color.opacity(0.3), category.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }

            if isFocusModeEnabled {
                FocusModeView(isEnabled: $isFocusModeEnabled, content: content, title: title)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
    }

    private var estimatedReadingTimeMinutes: Int {
        let words = content.split { $0 == " " || $0 == "\n" || $0 == "\t" }.count
        let minutes = Int(ceil(Double(words) / 200.0))
        return max(1, minutes)
    }

    @State private var scrollState = ScrollState()

    private func updateScrollProgress() {
        let scrollable = max(1, scrollState.contentHeight - scrollState.viewportHeight)
        let raw = (-scrollState.offset) / scrollable
        scrollProgress = min(max(raw, 0), 1)
    }

    private var parsedTable: ParsedDataTable? {
        ParsedDataTable.parse(from: content)
    }
}

private struct ParsedDataTable {
    let columns: [EnhancedDataTable.Column]
    let rows: [EnhancedDataTable.Row]

    static func parse(from text: String) -> ParsedDataTable? {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard let stateHeaderIndex = lines.firstIndex(of: "State") else { return nil }

        let expectedHeaders = [
            "State",
            "Prediction Error (ε)",
            "Precision (π)",
            "Threshold (θₜ)",
            "Somatic Bias (β)",
            "Key Signature"
        ]

        guard lines.count > stateHeaderIndex + expectedHeaders.count - 1 else { return nil }
        let actualHeaders = Array(lines[stateHeaderIndex..<(stateHeaderIndex + expectedHeaders.count)])
        guard actualHeaders == expectedHeaders else { return nil }

        let columns: [EnhancedDataTable.Column] = expectedHeaders.enumerated().map { index, header in
            switch index {
            case 0:
                return .init(header: header, width: 160, alignment: .leading)
            default:
                return .init(header: header, width: nil, alignment: .leading)
            }
        }

        var i = stateHeaderIndex + expectedHeaders.count
        var rows: [EnhancedDataTable.Row] = []

        func isMeaningful(_ line: String) -> Bool {
            !line.isEmpty
        }

        while i < lines.count {
            while i < lines.count, !isMeaningful(lines[i]) {
                i += 1
            }
            if i >= lines.count { break }

            var cells: [String] = []
            cells.reserveCapacity(6)

            for _ in 0..<6 {
                guard i < lines.count else { break }
                let line = lines[i]
                if !isMeaningful(line) {
                    break
                }
                cells.append(line)
                i += 1
            }

            guard cells.count == 6 else {
                break
            }

            rows.append(.init(cells: cells))
        }

        guard !rows.isEmpty else { return nil }
        return ParsedDataTable(columns: columns, rows: rows)
    }
}

private struct ScrollState {
    var offset: CGFloat = 0
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollViewportPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
