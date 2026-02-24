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

            if self.isCheckingForUpdates {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Checking for updates...")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 100)
            }
            else if self.updateAvailable {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Update Available")
                        .font(.headline.weight(.semibold))

                    Text("Version \(self.latestVersion) is available")
                        .foregroundStyle(.secondary)

                    if !self.updateNotes.isEmpty {
                        Text(self.updateNotes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    HStack(spacing: 12) {
                        Button("Download Update") {
                            // Handle download
                            self.dismiss()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Later") {
                            self.dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            else if !self.errorMessage.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Update Check Failed")
                        .font(.headline.weight(.semibold))

                    Text(self.errorMessage)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        self.checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            else {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("You're up to date")
                        .font(.headline.weight(.semibold))

                    Text("Version \(self.currentVersion)")
                        .foregroundStyle(.secondary)

                    Button("OK") {
                        self.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(30)
        .frame(width: 400, height: 300)
        .onAppear {
            self.checkForUpdates()
        }
    }

    private func checkForUpdates() {
        self.isCheckingForUpdates = true
        self.errorMessage = ""

        // Simulate update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isCheckingForUpdates = false

            // For now, assume no update is available
            // In a real app, this would check an API endpoint
            self.updateAvailable = false
        }
    }
}

#Preview {
    UpdateCheckView()
}
