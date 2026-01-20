import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let updates = [
        Update(
            version: "1.2.0",
            date: "January 2026",
            title: "Major Network Integration",
            features: [
                "Real-time network status monitoring",
                "Remote glossary and bibliography fetching",
                "Automatic content updates",
                "Enhanced search capabilities",
                "Network settings panel"
            ]
        ),
        Update(
            version: "1.1.0",
            date: "December 2025",
            title: "Table Parser System",
            features: [
                "Dynamic table parsing from multiple formats",
                "Markdown, CSV, TSV, and JSON support",
                "Export capabilities for all table formats",
                "Eliminated hardcoded table data"
            ]
        ),
        Update(
            version: "1.0.0",
            date: "November 2025",
            title: "Initial Release",
            features: [
                "Complete APGI framework reference",
                "Interactive navigation system",
                "Comprehensive search functionality",
                "Accessibility features throughout"
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVStack(spacing: 16) {
                        ForEach(updates) { update in
                            UpdateCard(update: update)
                        }

                        footer
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)

            Text("APGI Appendix Updates")
                .font(.title.bold())

            Text("Stay up to date with the latest features and improvements")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Divider()

            Text("Thank you for using APGI Appendix!")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 24) {
                Link("Online Documentation", destination: URL(string: "https://docs.apgi-framework.org")!)
                Link("Report Issues", destination: URL(string: "https://github.com/apgi/framework/issues")!)
            }
            .font(.caption)
        }
    }
}

struct UpdateCard: View {
    let update: Update

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(update.title)
                        .font(.headline.bold())

                    Text("Version \(update.version) • \(update.date)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(update.version)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(update.features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.top, 2)

                        Text(feature)
                            .font(.body)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct Update: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let title: String
    let features: [String]
}

#Preview {
    WhatsNewView()
}
