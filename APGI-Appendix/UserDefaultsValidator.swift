import Combine
import Foundation
import SwiftUI

// MARK: - UserDefaults Validator

@MainActor
class UserDefaultsValidator: ObservableObject {
  static let shared = UserDefaultsValidator()

  @Published var validationErrors: [ValidationError] = []
  @Published var isValidated = false

  private let defaults = UserDefaults.standard
  private let validationKey = "UserDefaultsValidated"

  private init() {
    self.validateAllSettings()
  }

  // MARK: - Public Methods

  func validateAllSettings() {
    self.validationErrors.removeAll()

    self.validateFontSize()
    self.validateWindowSettings()
    self.validateThemeSettings()
    // Note: NetworkSettings validation removed - app no longer depends on external API
    self.validateLoggingSettings()

    self.isValidated = self.validationErrors.isEmpty

    // Mark validation as completed for this session
    self.defaults.set(true, forKey: self.validationKey)

    if !self.validationErrors.isEmpty {
      self.logValidationErrors()
    }
  }

  func getValidatedFontSize() -> Double {
    let fontSize = self.defaults.double(forKey: "contentFontSize")

    // Validate font size range (10-24pt)
    if fontSize < 10 || fontSize > 24 {
      self.addError(.fontSizeOutOfRange, value: fontSize)
      return 15.0  // Default fallback
    }

    return fontSize
  }

  func setValidatedFontSize(_ fontSize: Double) {
    guard fontSize >= 10, fontSize <= 24 else {
      self.addError(.fontSizeOutOfRange, value: fontSize)
      return
    }

    self.defaults.set(fontSize, forKey: "contentFontSize")
  }

  func getValidatedWindowFrame(for windowId: String) -> NSRect {
    let key = "windowFrame_\(windowId)"

    guard let frameData = defaults.data(forKey: key),
      let frame = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: frameData)
    else {
      return NSRect(x: 100, y: 100, width: 1000, height: 800)  // Default
    }

    let rect = frame.rectValue

    // Validate window frame
    if rect.width < 400 || rect.width > 4000 || rect.height < 300 || rect.height > 3000
      || rect.minX < -2000 || rect.minX > 4000 || rect.minY < -2000 || rect.minY > 4000 {
      self.addError(.windowFrameInvalid, value: "\(rect)")
      return NSRect(x: 100, y: 100, width: 1000, height: 800)  // Default
    }

    return rect
  }

  func setValidatedWindowFrame(_ frame: NSRect, for windowId: String) {
    // Validate before saving
    guard frame.width >= 400, frame.width <= 4000,
      frame.height >= 300, frame.height <= 3000,
      frame.minX >= -2000, frame.minX <= 4000,
      frame.minY >= -2000, frame.minY <= 4000 else {
      self.addError(.windowFrameInvalid, value: "\(frame)")
      return
    }

    let key = "windowFrame_\(windowId)"
    let frameValue = NSValue(rect: frame)

    do {
      let frameData = try NSKeyedArchiver.archivedData(
        withRootObject: frameValue, requiringSecureCoding: true)
      self.defaults.set(frameData, forKey: key)
    } catch {
      self.addError(.serializationError, value: "Window frame serialization failed")
    }
  }

  func getValidatedThemeName() -> String {
    let themeName = self.defaults.string(forKey: "selectedTheme") ?? "system"

    let validThemes = ["system", "light", "dark", "highContrast"]

    if !validThemes.contains(themeName) {
      self.addError(.invalidTheme, value: themeName)
      return "system"  // Default fallback
    }

    return themeName
  }

  func setValidatedThemeName(_ themeName: String) {
    let validThemes = ["system", "light", "dark", "highContrast"]

    if !validThemes.contains(themeName) {
      self.addError(.invalidTheme, value: themeName)
      return
    }

    self.defaults.set(themeName, forKey: "selectedTheme")
  }

  // Note: NetworkSettings validation removed - app no longer depends on external API

  func resetToDefaults() {
    // Clear all app-specific settings
    let domain = Bundle.main.bundleIdentifier ?? "com.apgi.appendix"
    self.defaults.removePersistentDomain(forName: domain)

    // Reset to known good defaults
    self.setValidatedFontSize(15.0)
    self.setValidatedThemeName("system")

    self.validateAllSettings()
  }

  // MARK: - Private Methods

  private func validateFontSize() {
    _ = self.getValidatedFontSize()
  }

  private func validateWindowSettings() {
    // Validate main window frame
    _ = self.getValidatedWindowFrame(for: "main")
    _ = self.getValidatedWindowFrame(for: "timeline")
    _ = self.getValidatedWindowFrame(for: "glossary")
    _ = self.getValidatedWindowFrame(for: "simulator")
  }

  private func validateThemeSettings() {
    _ = self.getValidatedThemeName()

    // Validate boolean theme settings
    let booleanKeys = [
      "sidebarVisible", "focusModeEnabled", "enableAnimations", "highContrastMode",
      "autoSaveBookmarks"
    ]

    for key in booleanKeys {
      if self.defaults.object(forKey: key) != nil, !(self.defaults.object(forKey: key) is Bool) {
        self.addError(.invalidBooleanSetting, value: key)
        self.defaults.removeObject(forKey: key)
      }
    }
  }

  // Note: NetworkSettings validation removed - app no longer depends on external API

  private func validateLoggingSettings() {
    // Validate logging enabled setting
    if self.defaults.object(forKey: "errorLoggingEnabled") != nil,
      !(self.defaults.object(forKey: "errorLoggingEnabled") is Bool) {
      self.addError(.invalidBooleanSetting, value: "errorLoggingEnabled")
      self.defaults.removeObject(forKey: "errorLoggingEnabled")
    }
  }

  private func addError(_ type: ValidationErrorType, value: Any) {
    let error = ValidationError(type: type, value: value, timestamp: Date())
    self.validationErrors.append(error)

    // Log the validation error
    logWarning(
      "UserDefaults validation error: \(type.description) - Value: \(value)",
      context: "UserDefaultsValidator")
  }

  private func logValidationErrors() {
    for error in self.validationErrors {
      logError(
        NSError(
          domain: "UserDefaultsValidator", code: -1,
          userInfo: [
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
    case .invalidRefreshInterval, .invalidBooleanSetting, .serializationError:
      return "Error"
    }
  }
}

// MARK: - Network Settings

// Note: NetworkSettings struct removed - app no longer depends on external API

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
          self.validator.validateAllSettings()
        }

        Button("Reset to Defaults") {
          self.showingResetAlert = true
        }
        .foregroundColor(.red)
      }

      // Validation status
      HStack {
        Image(
          systemName: self.validator.isValidated
            ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        )
        .foregroundColor(self.validator.isValidated ? .green : .orange)

        Text(self.validator.isValidated ? "All settings validated" : "Validation issues found")
          .font(.subheadline)
      }

      // Validation errors
      if !self.validator.validationErrors.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Validation Issues:")
            .font(.headline)

          ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
              ForEach(self.validator.validationErrors) { error in
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
    .alert("Reset Settings", isPresented: self.$showingResetAlert) {
      Button("Cancel", role: .cancel) {
      }
      Button("Reset", role: .destructive) {
        self.validator.resetToDefaults()
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
        Text(self.error.type.description)
          .font(.caption)
          .fontWeight(.medium)

        Text("Value: \(String(describing: self.error.value))")
          .font(.caption2)
          .foregroundColor(.secondary)

        Text(self.error.timestamp, style: .time)
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
  func safeDouble(
    forKey defaultName: String, defaultValue: Double = 0.0, range: ClosedRange<Double>? = nil
  ) -> Double {
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

  func safeString(
    forKey defaultName: String, defaultValue: String = "", validValues: [String]? = nil
  ) -> String {
    let value = string(forKey: defaultName) ?? defaultValue

    if let validValues = validValues {
      return validValues.contains(value) ? value : defaultValue
    }

    return value
  }
}
