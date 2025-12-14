import SwiftUI

struct EnhancedContentCard: View {
    let title: String
    let content: String
    let category: SectionCategory
    let hasDataTable: Bool

    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    @State private var isFocusModeEnabled: Bool = false
    @State private var scrollProgress: Double = 0

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
                    .accessibilityLabel("Focus Mode")
                }

                Divider()
                    .background(category.color.opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("EnhancedContentCardScroll")).minY)
                        }
                        .frame(height: 0)

                        GlossaryHighlightedText(text: content)
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
