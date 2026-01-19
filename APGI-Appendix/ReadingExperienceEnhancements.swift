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

// MARK: - Whats New View

struct WhatsNewView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let updates = [
        Update(
            version: "1.2.0",
            date: "December 2024",
            title: "Enhanced Interactive Timeline",
            description: "New playback controls, speed adjustment, and event interaction for the Ignition Timeline.",
            features: ["Playback controls with play/pause", "Adjustable playback speed", "Interactive event details", "Phase indicators"]
        ),
        Update(
            version: "1.1.0",
            date: "November 2024",
            title: "APGI Simulator",
            description: "Interactive simulation environment for real-time parameter manipulation and system behavior visualization.",
            features: ["Real-time parameter controls", "Dynamic system visualization", "Predictive coding simulations", "Neuromodulatory modeling"]
        ),
        Update(
            version: "1.0.0",
            date: "October 2024",
            title: "Initial Release",
            description: "Complete APGI Framework reference with comprehensive content and interactive features.",
            features: ["Full framework documentation", "Interactive visualizations", "Comprehensive glossary", "Cross-referenced content"]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What's New")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 10)

                Text("Latest updates and improvements to the APGI Appendix")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 30)

                ForEach(updates) { update in
                    UpdateCard(update: update)
                }
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
}

private struct UpdateCard: View {
    let update: Update

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(update.version)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    Text(update.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(update.title)
                .font(.title3.weight(.medium))

            Text(update.description)
                .font(.body)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Features:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(update.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 2)

                        Text(feature)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
}

private struct Update: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let title: String
    let description: String
    let features: [String]
}

// MARK: - Quick Start Panel

struct QuickStartPanel: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection()

                QuickStartNavigationSection()
                FeaturesSection()
                WorkflowSection()
                KeyboardShortcutsSection()
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
}

private struct HeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start Guide")
                .font(.largeTitle.weight(.bold))

            Text("Get up and running with the APGI Appendix in minutes")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct QuickStartNavigationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🧭 Navigation")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                QuickStartItem(
                    icon: "sidebar.left",
                    title: "Three-Panel Layout",
                    description: "Categories → Sections → Content"
                )

                QuickStartItem(
                    icon: "magnifyingglass",
                    title: "Global Search",
                    description: "Press ⌘F to search everything"
                )

                QuickStartItem(
                    icon: "bookmark",
                    title: "Bookmarks",
                    description: "Press ⌘B to bookmark current section"
                )
            }
        }
    }
}

private struct FeaturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("✨ Key Features")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                QuickStartItem(
                    icon: "eye",
                    title: "Focus Mode",
                    description: "Distraction-free reading"
                )

                QuickStartItem(
                    icon: "play.circle",
                    title: "Interactive Timeline",
                    description: "Explore temporal dynamics"
                )

                QuickStartItem(
                    icon: "gearshape.2",
                    title: "APGI Simulator",
                    description: "Interactive parameter modeling"
                )
            }
        }
    }
}

private struct WorkflowSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📖 Recommended Workflow")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                QuickStartItem(
                    icon: "1.circle",
                    title: "Start with Methodology",
                    description: "Understand the framework foundation"
                )

                QuickStartItem(
                    icon: "2.circle",
                    title: "Explore Mathematical Framework",
                    description: "Learn the quantitative models"
                )

                QuickStartItem(
                    icon: "3.circle",
                    title: "Study Biological Implementation",
                    description: "Connect with neural systems"
                )
            }
        }
    }
}

private struct KeyboardShortcutsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⌨️ Essential Shortcuts")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                QuickStartItem(
                    icon: "commandkey",
                    title: "⌘F",
                    description: "Open search"
                )

                QuickStartItem(
                    icon: "commandkey",
                    title: "⌘B",
                    description: "Toggle bookmark"
                )

                QuickStartItem(
                    icon: "commandkey",
                    title: "⌘[ / ⌘]",
                    description: "Navigate sections"
                )
            }
        }
    }
}

private struct QuickStartItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
