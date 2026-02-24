import Combine
import Foundation
import SwiftUI

// MARK: - Version Info Manager

@MainActor
class VersionInfoManager: ObservableObject {
    static let shared = VersionInfoManager()

    @Published var version: String = ""
    @Published var build: String = ""
    @Published var bundleVersion: String = ""
    @Published var copyright: String = ""

    private init() {
        self.loadVersionInfo()
    }

    private func loadVersionInfo() {
        let bundle = Bundle.main
        guard let infoDict = bundle.infoDictionary else {
            self.version = "1.0.0"
            self.build = "2024.1"
            self.bundleVersion = "1"
            self.copyright = "© 2026 APGI"
            return
        }

        self.version = infoDict["CFBundleShortVersionString"] as? String ?? "1.0.0"

        self.build = infoDict["CFBundleVersion"] as? String ?? "1"

        self.bundleVersion = self.build
        self.bundleVersion = self.build

        self.copyright = infoDict["NSHumanReadableCopyright"] as? String ?? "© 2026 APGI Research Team"

        if self.build.isEmpty || self.build == self.version {
            self.build = "Build \(self.bundleVersion)"
        }
    }

    var versionText: String {
        "Version: \(self.version)"
    }

    var buildText: String {
        "Build: \(self.build)"
    }

    var fullVersionString: String {
        "\(self.version) (\(self.build))"
    }

    func refreshVersionInfo() {
        self.loadVersionInfo()
    }
}

// MARK: - Version Info View

struct VersionInfoView: View {
    @StateObject private var versionManager = VersionInfoManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.versionManager.versionText)
            Text(self.versionManager.buildText)
            Text(self.versionManager.copyright)
        }
        .font(.body)
        .foregroundColor(.primary)
    }
}

// MARK: - Bundle Info Extensions

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var appBuild: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "APGI Appendix"
    }

    var appDisplayName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? self.appName
    }

    var copyrightInfo: String {
        return infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© 2024 APGI Research Team"
    }
}
