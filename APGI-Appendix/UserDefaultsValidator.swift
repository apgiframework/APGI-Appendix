import Foundation
import SwiftUI
import Combine

// MARK: - UserDefaults Validator
@MainActor
class UserDefaultsValidator: ObservableObject {
    static let shared = UserDefaultsValidator()

    @Published var validationErrors: [ValidationError] = []
    @Published var isValidated = false

    private let defaults = UserDefaults.standard
    private let validationKey = "UserDefaultsValidated"

    private init() {
        validateAllSettings()
    }

    // MARK: - Public Methods

    func validateAllSettings() {
        validationErrors.removeAll()

        validateFontSize()
        validateWindowSettings()
        validateThemeSettings()
        validateNetworkSettings()
        validateBookmarkSettings()
        validateLoggingSettings()

        isValidated = validationErrors.isEmpty

        // Mark validation as completed for this session
        defaults.set(true, forKey: validationKey)

        if !validationErrors.isEmpty {
            logValidationErrors()
        }
    }

    func getValidatedFontSize() -> Double {
        let fontSize = defaults.double(forKey: "contentFontSize")

        // Validate font size range (10-24pt)
        if fontSize < 10 || fontSize > 24 {
            addError(.fontSizeOutOfRange, value: fontSize)
            return 15.0 // Default fallback
        }

        return fontSize
    }

    func setValidatedFontSize(_ fontSize: Double) {
        guard fontSize >= 10 && fontSize <= 24 else {
            addError(.fontSizeOutOfRange, value: fontSize)
            return
        }

        defaults.set(fontSize, forKey: "contentFontSize")
    }

    func getValidatedWindowFrame(for windowId: String) -> NSRect {
        let key = "windowFrame_\(windowId)"

        guard let frameData = defaults.data(forKey: key),
              let frame = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: frameData) else {
            return NSRect(x: 100, y: 100, width: 1000, height: 800) // Default
        }

        let rect = frame.rectValue

        // Validate window frame
        if rect.width < 400 || rect.width > 4000 ||
           rect.height < 300 || rect.height > 3000 ||
           rect.minX < -2000 || rect.minX > 4000 ||
           rect.minY < -2000 || rect.minY > 4000 {
            addError(.windowFrameInvalid, value: "\(rect)")
            return NSRect(x: 100, y: 100, width: 1000, height: 800) // Default
        }

        return rect
    }

    func setValidatedWindowFrame(_ frame: NSRect, for windowId: String) {
        // Validate before saving
        guard frame.width >= 400 && frame.width <= 4000 &&
              frame.height >= 300 && frame.height <= 3000 &&
              frame.minX >= -2000 && frame.minX <= 4000 &&
              frame.minY >= -2000 && frame.minY <= 4000 else {
            addError(.windowFrameInvalid, value: "\(frame)")
            return
        }

        let key = "windowFrame_\(windowId)"
        let frameValue = NSValue(rect: frame)

        do {
            let frameData = try NSKeyedArchiver.archivedData(withRootObject: frameValue, requiringSecureCoding: true)
            defaults.set(frameData, forKey: key)
        } catch {
            addError(.serializationError, value: "Window frame serialization failed")
        }
    }

    func getValidatedThemeName() -> String {
        let themeName = defaults.string(forKey: "selectedTheme") ?? "system"

        let validThemes = ["system", "light", "dark", "highContrast"]

        if !validThemes.contains(themeName) {
            addError(.invalidTheme, value: themeName)
            return "system" // Default fallback
        }

        return themeName
    }

    func setValidatedThemeName(_ themeName: String) {
        let validThemes = ["system", "light", "dark", "highContrast"]

        if !validThemes.contains(themeName) {
            addError(.invalidTheme, value: themeName)
            return
        }

        defaults.set(themeName, forKey: "selectedTheme")
    }

    func getValidatedNetworkSettings() -> NetworkSettings {
        let settings = NetworkSettings(
            enableRemoteContent: defaults.bool(forKey: "enableRemoteContent"),
            autoRefreshInterval: defaults.double(forKey: "autoRefreshInterval"),
            useCellularData: defaults.bool(forKey: "useCellularData")
        )

        // Validate auto refresh interval (1-168 hours)
        if settings.autoRefreshInterval < 1 || settings.autoRefreshInterval > 168 {
            addError(.invalidRefreshInterval, value: settings.autoRefreshInterval)
            return NetworkSettings(enableRemoteContent: settings.enableRemoteContent,
                                autoRefreshInterval: 24, // Default
                                useCellularData: settings.useCellularData)
        }

        return settings
    }

    func setValidatedNetworkSettings(_ settings: NetworkSettings) {
        guard settings.autoRefreshInterval >= 1 && settings.autoRefreshInterval <= 168 else {
            addError(.invalidRefreshInterval, value: settings.autoRefreshInterval)
            return
        }

        defaults.set(settings.enableRemoteContent, forKey: "enableRemoteContent")
        defaults.set(settings.autoRefreshInterval, forKey: "autoRefreshInterval")
        defaults.set(settings.useCellularData, forKey: "useCellularData")
    }

    func getValidatedBookmarks() -> [String] {
        guard let bookmarkData = defaults.array(forKey: "bookmarkedTabs") as? [String] else {
            return []
        }

        // Validate bookmark data structure
        let validBookmarks = bookmarkData.filter { bookmark in
            // Check if bookmark is a non-empty string
            return !bookmark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if validBookmarks.count != bookmarkData.count {
            addError(.invalidBookmarkData, value: "Found \(bookmarkData.count - validBookmarks.count) invalid bookmarks")
        }

        return validBookmarks
    }

    func setValidatedBookmarks(_ bookmarks: [String]) {
        let validBookmarks = bookmarks.filter { bookmark in
            return !bookmark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        defaults.set(validBookmarks, forKey: "bookmarkedTabs")
    }

    func resetToDefaults() {
        // Clear all app-specific settings
        let domain = Bundle.main.bundleIdentifier ?? "com.apgi.appendix"
        defaults.removePersistentDomain(forName: domain)

        // Reset to known good defaults
        setValidatedFontSize(15.0)
        setValidatedThemeName("system")
        setValidatedNetworkSettings(NetworkSettings())
        setValidatedBookmarks([])

        validateAllSettings()
    }

    // MARK: - Private Methods

    private func validateFontSize() {
        _ = getValidatedFontSize()
    }

    private func validateWindowSettings() {
        // Validate main window frame
        _ = getValidatedWindowFrame(for: "main")
        _ = getValidatedWindowFrame(for: "timeline")
        _ = getValidatedWindowFrame(for: "glossary")
        _ = getValidatedWindowFrame(for: "simulator")
    }

    private func validateThemeSettings() {
        _ = getValidatedThemeName()

        // Validate boolean theme settings
        let booleanKeys = ["sidebarVisible", "focusModeEnabled", "enableAnimations", "highContrastMode", "autoSaveBookmarks"]

        for key in booleanKeys {
            if defaults.object(forKey: key) != nil && !(defaults.object(forKey: key) is Bool) {
                addError(.invalidBooleanSetting, value: key)
                defaults.removeObject(forKey: key)
            }
        }
    }

    private func validateNetworkSettings() {
        _ = getValidatedNetworkSettings()
    }

    private func validateBookmarkSettings() {
        _ = getValidatedBookmarks()
    }

    private func validateLoggingSettings() {
        // Validate logging enabled setting
        if defaults.object(forKey: "errorLoggingEnabled") != nil && !(defaults.object(forKey: "errorLoggingEnabled") is Bool) {
            addError(.invalidBooleanSetting, value: "errorLoggingEnabled")
            defaults.removeObject(forKey: "errorLoggingEnabled")
        }
    }

    private func addError(_ type: ValidationErrorType, value: Any) {
        let error = ValidationError(type: type, value: value, timestamp: Date())
        validationErrors.append(error)

        // Log the validation error
        logWarning("UserDefaults validation error: \(type.description) - Value: \(value)", context: "UserDefaultsValidator")
    }

    private func logValidationErrors() {
        for error in validationErrors {
            logError(NSError(domain: "UserDefaultsValidator", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Validation error: \(error.type.description)",
                "ValidationValue": error.value,
                "ValidationTimestamp": error.timestamp
            ]), context: "UserDefaultsValidator")
        }
    }
}

// MARK: - Validation Error
struct ValidationError: Identifiable {
    let id = UUID()
    let type: ValidationErrorType
    let value: Any
    let timestamp: Date
}

// MARK: - Validation Error Types
enum ValidationErrorType {
    case fontSizeOutOfRange
    case windowFrameInvalid
    case invalidTheme
    case invalidRefreshInterval
    case invalidBookmarkData
    case invalidBooleanSetting
    case serializationError

    var description: String {
        switch self {
        case .fontSizeOutOfRange:
            return "Font size out of range (must be 10-24pt)"
        case .windowFrameInvalid:
            return "Window frame dimensions invalid"
        case .invalidTheme:
            return "Invalid theme name"
        case .invalidRefreshInterval:
            return "Auto refresh interval out of range (must be 1-168 hours)"
        case .invalidBookmarkData:
            return "Invalid bookmark data format"
        case .invalidBooleanSetting:
            return "Invalid boolean setting value"
        case .serializationError:
            return "Data serialization failed"
        }
    }

    var severity: String {
        switch self {
        case .fontSizeOutOfRange, .windowFrameInvalid, .invalidTheme:
            return "Warning"
        case .invalidRefreshInterval, .invalidBookmarkData, .invalidBooleanSetting, .serializationError:
            return "Error"
        }
    }
}

// MARK: - Network Settings
struct NetworkSettings {
    let enableRemoteContent: Bool
    let autoRefreshInterval: Double
    let useCellularData: Bool

    init(enableRemoteContent: Bool = true, autoRefreshInterval: Double = 24, useCellularData: Bool = false) {
        self.enableRemoteContent = enableRemoteContent
        self.autoRefreshInterval = autoRefreshInterval
        self.useCellularData = useCellularData
    }
}

// MARK: - UserDefaults Validation View
struct UserDefaultsValidationView: View {
    @StateObject private var validator = UserDefaultsValidator.shared
    @State private var showingResetAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Settings Validation")
                    .font(.title2.bold())

                Spacer()

                Button("Validate All") {
                    validator.validateAllSettings()
                }

                Button("Reset to Defaults") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            }

            // Validation status
            HStack {
                Image(systemName: validator.isValidated ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(validator.isValidated ? .green : .orange)

                Text(validator.isValidated ? "All settings validated" : "Validation issues found")
                    .font(.subheadline)
            }

            // Validation errors
            if !validator.validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Validation Issues:")
                        .font(.headline)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(validator.validationErrors) { error in
                                ValidationErrorView(error: error)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            } else {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("All user settings are valid")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .padding()
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                validator.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
}

// MARK: - Validation Error View
struct ValidationErrorView: View {
    let error: ValidationError

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.type.description)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("Value: \(String(describing: error.value))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(error.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Safe UserDefaults Extensions
extension UserDefaults {
    func safeDouble(forKey defaultName: String, defaultValue: Double = 0.0, range: ClosedRange<Double>? = nil) -> Double {
        let value = double(forKey: defaultName)

        if let range = range {
            return range.contains(value) ? value : defaultValue
        }

        return value
    }

    func safeBool(forKey defaultName: String, defaultValue: Bool = false) -> Bool {
        guard object(forKey: defaultName) is Bool else {
            removeObject(forKey: defaultName)
            return defaultValue
        }

        return bool(forKey: defaultName)
    }

    func safeString(forKey defaultName: String, defaultValue: String = "", validValues: [String]? = nil) -> String {
        let value = string(forKey: defaultName) ?? defaultValue

        if let validValues = validValues {
            return validValues.contains(value) ? value : defaultValue
        }

        return value
    }
}
