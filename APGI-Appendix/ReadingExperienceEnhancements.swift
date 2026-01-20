import SwiftUI

struct FocusModeView: View {
    @Binding var isEnabled: Bool
    let content: String
    let title: String

    @AppStorage("contentFontSize") private var fontSize: Double = 15.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isEnabled = false
                }

            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.title2.bold())

                    Spacer()

                    Button {
                        isEnabled = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .apgiAccessibility(
                        label: "Close focus mode",
                        hint: "Return to the main content view",
                        traits: .isButton
                    )
                    .keyboardShortcut("w", modifiers: [.command])
                }
                .padding()
                .background(.bar)

                ScrollView {
                    LazyGlossaryHighlightedContent(text: content)
                        .font(.system(size: fontSize, design: .serif))
                        .lineSpacing(8)
                        .padding(40)
                        .frame(maxWidth: 650, alignment: .leading)
                        .textSelection(.enabled)
                }
                .background(.background)
            }
            .frame(maxWidth: 800, maxHeight: 700)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
    }
}

struct ReadingProgressView: View {
    let progress: Double
    let estimatedTime: Int

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: max(0, geometry.size.width * progress))
                }
            }
            .frame(height: 4)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("\(estimatedTime) min")
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(.secondary)
        }
        .frame(height: 20)
    }
}

struct FontSizeControl: View {
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0

    var body: some View {
        HStack(spacing: 8) {
            Button {
                fontSize = max(12, fontSize - 1)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .disabled(fontSize <= 12)

            Text("\(Int(fontSize))pt")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 40)

            Button {
                fontSize = min(24, fontSize + 1)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .disabled(fontSize >= 24)
        }
        .buttonStyle(.borderless)
    }
}

extension View {
    func apgiAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

private struct WhatsNewUpdate: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let title: String
    let description: String
    let features: [String]
}
