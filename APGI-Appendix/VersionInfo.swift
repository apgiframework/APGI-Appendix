import Foundation
import SwiftUI
import Combine

// MARK: - Version Info Manager
@MainActor
class VersionInfoManager: ObservableObject {
    static let shared = VersionInfoManager()
    
    @Published var version: String = ""
    @Published var build: String = ""
    @Published var bundleVersion: String = ""
    @Published var copyright: String = ""
    
    private init() {
        loadVersionInfo()
    }
    
    private func loadVersionInfo() {
        let bundle = Bundle.main
        guard let infoDict = bundle.infoDictionary else {
            version = "1.0.0"
            build = "2024.1"
            bundleVersion = "1"
            copyright = "© 2026 APGI"
            return
        }
        
        version = infoDict["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        build = infoDict["CFBundleVersion"] as? String ?? "1"
        
        bundleVersion = build
        bundleVersion = build
        
        copyright = infoDict["NSHumanReadableCopyright"] as? String ?? "© 2026 APGI Research Team"
        
        if build.isEmpty || build == version {
            build = "Build \(bundleVersion)"
        }
    }
    
    var versionText: String {
        "Version: \(version)"
    }
    
    var buildText: String {
        "Build: \(build)"
    }
    
    var fullVersionString: String {
        "\(version) (\(build))"
    }
    
    func refreshVersionInfo() {
        loadVersionInfo()
    }
}

// MARK: - Version Info View
struct VersionInfoView: View {
    @StateObject private var versionManager = VersionInfoManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(versionManager.versionText)
            Text(versionManager.buildText)
            Text(versionManager.copyright)
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
        return infoDictionary?["CFBundleDisplayName"] as? String ?? appName
    }
    
    var copyrightInfo: String {
        return infoDictionary?["NSHumanReadableCopyright"] as? String ?? "© 2024 APGI Research Team"
    }
}
