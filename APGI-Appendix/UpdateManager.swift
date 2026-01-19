import SwiftUI
import Foundation
import Combine

@MainActor
final class UpdateManager: ObservableObject {
    @Published var hasUpdate = false
    @Published var updateInfo: UpdateInfo?
    @Published var isCheckingForUpdates = false
    @Published var lastError: NetworkError?
    @Published var lastCheckDate: Date?

    private let networkManager = NetworkManager.shared
    private let currentVersion = "1.0.0"
    private let currentBuild = "2024.1"

    struct UpdateInfo: Codable {
        let version: String
        let build: String
        let releaseNotes: String
        let downloadURL: String
        let required: Bool
        let releaseDate: String
    }

    func checkForUpdates() async {
        guard let url = networkManager.validateURL("https://api.apgi-framework.org/updates.json") else {
            lastError = .invalidURL
            return
        }

        isCheckingForUpdates = true
        lastError = nil

        do {
            let data = try await networkManager.fetchExternalResourceWithFallback(
                primaryURL: url,
                fallbackURL: networkManager.validateURL("https://raw.githubusercontent.com/apgi/framework/main/updates.json")
            )

            let decoder = JSONDecoder()
            let updates = try decoder.decode([UpdateInfo].self, from: data)

            if let latestUpdate = updates.first {
                hasUpdate = isNewerVersion(latestUpdate)
                updateInfo = latestUpdate
            }

            lastCheckDate = Date()

        } catch let error as NetworkError {
            lastError = error
        } catch {
            lastError = .unknown(error)
        }

        isCheckingForUpdates = false
    }

    private func isNewerVersion(_ update: UpdateInfo) -> Bool {
        // Simple version comparison (ignores build for now)
        return update.version > currentVersion
    }

    func downloadUpdate() {
        guard let updateInfo = updateInfo,
              let url = URL(string: updateInfo.downloadURL) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

struct UpdateCheckView: View {
    @StateObject private var updateManager = UpdateManager()
    @State private var showUpdateSheet = false

    var body: some View {
        VStack(spacing: 16) {
            if updateManager.isCheckingForUpdates {
                ProgressView("Checking for updates...")
            } else if let updateInfo = updateManager.updateInfo, updateManager.hasUpdate {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text("Update Available")
                                .font(.headline)
                            Text("Version \(updateInfo.version) is available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    if updateInfo.required {
                        Text("This update is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Button("Download Update") {
                            updateManager.downloadUpdate()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Release Notes") {
                            showUpdateSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(8)
            } else if let lastCheckDate = updateManager.lastCheckDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Up to date (checked \(lastCheckDate, style: .relative))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Updates not checked yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Check for Updates") {
                Task {
                    await updateManager.checkForUpdates()
                }
            }
            .disabled(updateManager.isCheckingForUpdates)
        }
        .sheet(isPresented: $showUpdateSheet) {
            if let updateInfo = updateManager.updateInfo {
                UpdateDetailsView(updateInfo: updateInfo)
            }
        }
        .task {
            await updateManager.checkForUpdates()
        }
    }
}

struct UpdateDetailsView: View {
    let updateInfo: UpdateManager.UpdateInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version \(updateInfo.version)")
                            .font(.title2.bold())
                        Text("Build \(updateInfo.build)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Released: \(updateInfo.releaseDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if updateInfo.required {
                        Label("Required Update", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Release Notes")
                            .font(.headline)

                        Text(updateInfo.releaseNotes)
                            .font(.body)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Update Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Button("Download") {
                        if let url = URL(string: updateInfo.downloadURL) {
                            NSWorkspace.shared.open(url)
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
