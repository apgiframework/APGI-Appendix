import SwiftUI

// MARK: - Update Check View

struct UpdateCheckView: View {
    @State private var isCheckingForUpdates = false
    @State private var updateAvailable = false
    @State private var currentVersion = "1.0.0"
    @State private var latestVersion = "1.0.0"
    @State private var updateNotes = ""
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Check for Updates")
                .font(.title2.weight(.bold))
                .padding(.top)

            if isCheckingForUpdates {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Checking for updates...")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 100)
            } else if updateAvailable {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Update Available")
                        .font(.headline.weight(.semibold))

                    Text("Version \(latestVersion) is available")
                        .foregroundStyle(.secondary)

                    if !updateNotes.isEmpty {
                        Text(updateNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    HStack(spacing: 12) {
                        Button("Download Update") {
                            // Handle download
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Later") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else if !errorMessage.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Update Check Failed")
                        .font(.headline.weight(.semibold))

                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("You're up to date")
                        .font(.headline.weight(.semibold))

                    Text("Version \(currentVersion)")
                        .foregroundStyle(.secondary)

                    Button("OK") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(30)
        .frame(width: 400, height: 300)
        .onAppear {
            checkForUpdates()
        }
    }

    private func checkForUpdates() {
        isCheckingForUpdates = true
        errorMessage = ""

        // Simulate update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCheckingForUpdates = false

            // For now, assume no update is available
            // In a real app, this would check an API endpoint
            updateAvailable = false
        }
    }
}

#Preview {
    UpdateCheckView()
}
