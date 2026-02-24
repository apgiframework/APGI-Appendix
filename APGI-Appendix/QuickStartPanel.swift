import SwiftUI

struct QuickStartPanel: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        QuickStep(
            number: 1,
            title: "Navigate the Content",
            description: "Use the sidebar to browse through different categories and sections. Click on any item to view its details.",
            icon: "sidebar.left"
        ),
        QuickStep(
            number: 2,
            title: "Search for Information",
            description: "Press Cmd+F to open the search bar. You can search across all content or limit your search to specific areas.",
            icon: "magnifyingglass"
        ),
        QuickStep(
            number: 3,
            title: "Use Keyboard Shortcuts",
            description: "Navigate quickly with keyboard shortcuts. Press Cmd+K to see all available shortcuts.",
            icon: "keyboard"
        ),
        QuickStep(
            number: 4,
            title: "Customize Your Experience",
            description: "Open Settings to adjust font sizes, enable remote content, and configure other preferences.",
            icon: "gear"
        ),
        QuickStep(
            number: 5,
            title: "Access Help Resources",
            description: "Use the Help menu to access documentation, report issues, and check for updates.",
            icon: "questionmark.circle"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") {
                    self.dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ScrollView {
                VStack(spacing: 24) {
                    self.header
                    self.stepsList
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Welcome to APGI Appendix")
                .font(.title.bold())

            Text("Get started quickly with this step-by-step guide")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var stepsList: some View {
        VStack(spacing: 16) {
            ForEach(self.steps) { step in
                StepCard(step: step)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            Divider()

            Text("Ready to explore?")
                .font(.headline)

            HStack(spacing: 16) {
                Button("Open Documentation") {
                    // Open online documentation
                    if let url = URL(string: "https://docs.apgi-framework.org") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("View Shortcuts") {
                    // Show keyboard shortcuts
                    NSApp.sendAction(Selector(("showKeyCommands:")), to: nil, from: nil)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct StepCard: View {
    let step: QuickStep

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            Text("\(self.step.number)")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: self.step.icon)
                        .foregroundColor(.blue)

                    Text(self.step.title)
                        .font(.headline.bold())
                }

                Text(self.step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct QuickStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
    let icon: String
}

#Preview {
    QuickStartPanel()
}
