import AppKit
import SwiftUI

// MARK: - Update Response Model

struct UpdateResponse: Codable {
  let latestVersion: String
  let minimumVersion: String?
  let releaseNotes: String
  let downloadURL: String?
  let releaseDate: String?
  let isCritical: Bool?

  // Signature fields for cryptographic verification
  let signature: String?  // Base64-encoded signature
  let keyId: String?  // Key identifier used for signing
  let algorithm: String?  // Signature algorithm (e.g., "P256-ECDSA", "Ed25519")
}

// MARK: - Update Check View

struct UpdateCheckView: View {
  @State private var isCheckingForUpdates = false
  @State private var updateAvailable = false
  @State private var currentVersion = Bundle.main.appVersion
  @State private var latestVersion = Bundle.main.appVersion
  @State private var updateNotes = ""
  @State private var errorMessage = ""
  @State private var downloadURL: URL?
  @State private var isCriticalUpdate = false
  @State private var retryCount = 0
  private let maxRetries = 3
  @State private var securityError = ""

  @Environment(\.dismiss) private var dismiss

  private var updateEndpoint: String {
    "https://api.apgiframework.com/updates.json"
  }

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
      } else if self.updateAvailable {
        VStack(spacing: 16) {
          Image(
            systemName: isCriticalUpdate ? "exclamationmark.circle.fill" : "arrow.down.circle.fill"
          )
          .font(.system(size: 48))
          .foregroundStyle(isCriticalUpdate ? .red : .green)

          Text(isCriticalUpdate ? "Critical Update Available" : "Update Available")
            .font(.headline.weight(.semibold))

          Text("Version \(self.latestVersion) is available")
            .foregroundStyle(.secondary)

          if !self.updateNotes.isEmpty {
            Text(self.updateNotes)
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
              .frame(maxHeight: 80)
          }

          HStack(spacing: 12) {
            Button("Download Update") {
              self.openDownloadURL()
            }
            .buttonStyle(.borderedProminent)

            Button("Later") {
              self.dismiss()
            }
            .buttonStyle(.bordered)
          }
        }
      } else if !self.securityError.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "lock.shield.fill")
            .font(.system(size: 48))
            .foregroundStyle(.red)

          Text("Security Verification Failed")
            .font(.headline.weight(.semibold))

          Text(self.securityError)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

          Text("This update cannot be trusted. Please download manually from the official website.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

          HStack(spacing: 12) {
            Button("Open Website") {
              if let url = URL(string: "https://apgiframework.com") {
                NSWorkspace.shared.open(url)
              }
              self.dismiss()
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss") {
              self.dismiss()
            }
            .buttonStyle(.bordered)
          }
        }
      } else if !self.errorMessage.isEmpty {
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
            self.retryCount = 0
            self.checkForUpdates()
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
    .frame(width: 400, height: 320)
    .onAppear {
      self.checkForUpdates()
    }
  }

  private func checkForUpdates() {
    guard NetworkManager.shared.isConnected else {
      self.errorMessage =
        "No internet connection. Please check your network settings and try again."
      self.isCheckingForUpdates = false
      return
    }

    self.isCheckingForUpdates = true
    self.errorMessage = ""
    self.securityError = ""
    self.updateAvailable = false
    self.downloadURL = nil
    self.currentVersion = Bundle.main.appVersion

    Task {
      await performUpdateCheck()
    }
  }

  private func performUpdateCheck() async {
    // Try primary endpoint first, then fallback
    let endpoints = [updateEndpoint]

    for endpoint in endpoints {
      if let result = await checkEndpoint(endpoint) {
        await MainActor.run {
          self.processUpdateResult(result)
        }
        return
      }
    }

    // All endpoints failed
    await MainActor.run {
      self.isCheckingForUpdates = false
      if self.retryCount < maxRetries {
        self.retryCount += 1
        self.errorMessage =
          "Unable to reach update server. Retry \(self.retryCount)/\(self.maxRetries)..."
        Task {
          try? await Task.sleep(nanoseconds: 2_000_000_000)
          await performUpdateCheck()
        }
      } else {
        self.errorMessage =
          "Unable to check for updates after \(maxRetries) attempts. Please try again later."
      }
    }
  }

  private func checkEndpoint(_ endpoint: String) async -> UpdateResponse? {
    guard let url = URL(string: endpoint) else { return nil }

    var request = URLRequest(url: url)
    request.timeoutInterval = 30
    request.setValue("APGI-Appendix/\(currentVersion)", forHTTPHeaderField: "User-Agent")

    do {
      let (data, response) = try await APGIAPI.session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        return nil
      }

      let updateResponse = try JSONDecoder().decode(UpdateResponse.self, from: data)
      return updateResponse
    } catch {
      return nil
    }
  }

  private func processUpdateResult(_ result: UpdateResponse) {
    Task {
      // Verify cryptographic signature before processing
      let validationResult = await UpdateSignatureActor.sharedVerifier.validateUpdate(
        result,
        signature: result.signature,
        keyId: result.keyId
      )

      // Validate download URL if present (outside MainActor context)
      var validDownloadURL: URL?
      if let downloadURLString = result.downloadURL {
        let isValidURL = await UpdateSignatureActor.sharedVerifier.validateDownloadURL(
          downloadURLString)
        if isValidURL {
          validDownloadURL = URL(string: downloadURLString)
        } else {
          await MainActor.run {
            logSecurityEvent("Download URL rejected by policy: \(downloadURLString)")
          }
        }
      }

      await MainActor.run {
        guard validationResult.isValid else {
          self.isCheckingForUpdates = false
          self.securityError =
            validationResult.errorReason ?? "Update signature verification failed"
          self.logSecurityEvent("Update rejected: \(self.securityError)")
          return
        }

        self.downloadURL = validDownloadURL
        self.isCheckingForUpdates = false
        self.latestVersion = result.latestVersion
        self.updateNotes = result.releaseNotes
        self.isCriticalUpdate = result.isCritical ?? false

        let comparison = compareVersions(self.currentVersion, result.latestVersion)

        if comparison == .orderedAscending {
          // Check minimum version requirement
          if let minimumVersion = result.minimumVersion,
            compareVersions(self.currentVersion, minimumVersion) == .orderedAscending {
            self.isCriticalUpdate = true
          }
          self.updateAvailable = true
        } else {
          self.updateAvailable = false
        }

        // Cache last check timestamp
        UserDefaults.standard.set(Date(), forKey: "lastUpdateCheck")
      }
    }
  }

  private func logSecurityEvent(_ message: String) {
    logInfo("[SECURITY] \(message)", context: "UpdateCheckView")
  }

  private func openDownloadURL() {
    if let url = self.downloadURL {
      URLValidator.shared.openSafely(url.absoluteString) {
        if let fallbackURL = URL(string: "https://apgiframework.com") {
          NSWorkspace.shared.open(fallbackURL)
        }
      }
    } else {
      // Fallback to website
      if let url = URL(string: "https://apgiframework.com") {
        NSWorkspace.shared.open(url)
      }
    }
    self.dismiss()
  }

  private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
    let v1Components = v1.components(separatedBy: ".")
    let v2Components = v2.components(separatedBy: ".")

    for i in 0..<max(v1Components.count, v2Components.count) {
      let v1Part = i < v1Components.count ? Int(v1Components[i]) ?? 0 : 0
      let v2Part = i < v2Components.count ? Int(v2Components[i]) ?? 0 : 0

      if v1Part < v2Part {
        return .orderedAscending
      } else if v1Part > v2Part {
        return .orderedDescending
      }
    }

    return .orderedSame
  }
}

#Preview {
  UpdateCheckView()
}
