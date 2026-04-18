import SwiftUI

struct FocusModeView: View {
  @Binding var isEnabled: Bool
  let content: String
  let title: String

  @AppStorage("contentFontSize") private var fontSize: Double = 15.0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .onTapGesture {
            self.isEnabled = false
          }

        VStack(spacing: 0) {
          HStack {
            Text(self.title)
              .font(.title2.bold())

            Spacer()

            Button {
              self.isEnabled = false
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
            LazyGlossaryHighlightedContent(text: self.content)
              .font(.system(size: self.fontSize, design: .serif))
              .lineSpacing(8)
              .padding(geometry.size.width > 600 ? 40 : 20)  // Responsive padding
              .frame(maxWidth: geometry.size.width > 600 ? 650 : .infinity, alignment: .leading)  // Responsive width
              .textSelection(.enabled)
          }
          .background(.background)
        }
        .frame(
          width: min(geometry.size.width * 0.9, 800),  // Responsive width
          height: min(geometry.size.height * 0.9, 700)  // Responsive height
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)  // Center the overlay
      }
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
            .frame(width: max(0, geometry.size.width * self.progress))
        }
      }
      .frame(height: 4)

      HStack(spacing: 4) {
        Image(systemName: "clock")
          .font(.caption)
        Text("\(self.estimatedTime) min")
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
        self.fontSize = max(12, self.fontSize - 1)
      } label: {
        Image(systemName: "textformat.size.smaller")
      }
      .disabled(self.fontSize <= 12)

      Text("\(Int(self.fontSize))pt")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .frame(width: 40)

      Button {
        self.fontSize = min(24, self.fontSize + 1)
      } label: {
        Image(systemName: "textformat.size.larger")
      }
      .disabled(self.fontSize >= 24)
    }
    .buttonStyle(.borderless)
  }
}

extension View {
  func apgiAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = [])
    -> some View
  {
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
