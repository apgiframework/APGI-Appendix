import SwiftUI

extension Color {
  static let apgiBlue = Color(hue: 0.55, saturation: 0.6, brightness: 0.9)
  static let apgiPurple = Color(hue: 0.75, saturation: 0.5, brightness: 0.85)
  static let apgiGreen = Color(hue: 0.35, saturation: 0.5, brightness: 0.8)
  static let apgiOrange = Color(hue: 0.08, saturation: 0.7, brightness: 0.95)
  static let apgiRed = Color(hue: 0.98, saturation: 0.6, brightness: 0.9)

  // Primary Brand Colors
  static let apgiPrimary = Color(red: 0.45, green: 0.55, blue: 0.95)
  static let apgiSecondary = Color(red: 0.75, green: 0.45, blue: 0.85)
  static let apgiAccent = Color(red: 0.95, green: 0.65, blue: 0.35)

  // Semantic Colors
  static let apgiSuccess = Color(red: 0.35, green: 0.85, blue: 0.55)
  static let apgiWarning = Color(red: 0.95, green: 0.75, blue: 0.35)
  static let apgiDanger = Color(red: 0.95, green: 0.35, blue: 0.45)
  static let apgiInfo = Color(red: 0.35, green: 0.75, blue: 0.95)

  // Neural Activity States
  static let neuralActive = Color(red: 0.95, green: 0.35, blue: 0.35)
  static let neuralModerate = Color(red: 0.95, green: 0.75, blue: 0.35)
  static let neuralLow = Color(red: 0.35, green: 0.75, blue: 0.95)
  static let neuralInhibit = Color(red: 0.55, green: 0.55, blue: 0.65)

  // Gradient Backgrounds
  static let gradientStart = Color(red: 0.08, green: 0.12, blue: 0.18)
  static let gradientEnd = Color(red: 0.15, green: 0.18, blue: 0.25)

  // Surface Colors
  static let surfacePrimary = Color(NSColor.windowBackgroundColor)
  static let surfaceSecondary = Color(NSColor.controlBackgroundColor)

  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b)
  }

  func toHex() -> String? {
    // This is a simplified version for common colors
    if self == .blue { return "#007AFF" }
    if self == .purple { return "#AF52DE" }
    if self == .green { return "#34C759" }
    if self == .orange { return "#FF9500" }
    if self == .pink { return "#FF2D55" }
    return nil
  }
}

enum APGITypography {
  // Display - Hero sections
  static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
  static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)

  // Title - Section headers
  static let titleLarge = Font.system(size: 28, weight: .bold)
  static let titleMedium = Font.system(size: 22, weight: .semibold)
  static let titleSmall = Font.system(size: 18, weight: .semibold)

  // Body - Main content
  static let bodyLarge = Font.system(size: 17, weight: .regular)
  static let bodyMedium = Font.system(size: 15, weight: .regular)
  static let bodySmall = Font.system(size: 13, weight: .regular)

  // Label - UI elements
  static let labelLarge = Font.system(size: 14, weight: .medium)
  static let labelMedium = Font.system(size: 12, weight: .medium)
  static let labelSmall = Font.system(size: 10, weight: .medium)

  // Monospace - Code/Data
  static let monoLarge = Font.system(size: 15, weight: .regular, design: .monospaced)
  static let monoMedium = Font.system(size: 13, weight: .regular, design: .monospaced)
}

enum APGISpacing {
  static let xxs: CGFloat = 2
  static let xs: CGFloat = 4  // alias for extraSmall
  static let extraSmall: CGFloat = 4
  static let sm: CGFloat = 6  // alias for small
  static let small: CGFloat = 6
  static let md: CGFloat = 10  // alias for medium
  static let medium: CGFloat = 10
  static let lg: CGFloat = 14  // alias for large
  static let large: CGFloat = 14
  static let extraLarge: CGFloat = 16
  static let xl: CGFloat = 24
  static let xxl: CGFloat = 32
  static let xxxl: CGFloat = 48

  // Contextual Spacing
  static let cardPadding: CGFloat = 20
  static let sectionSpacing: CGFloat = 28
  static let screenMargin: CGFloat = 24
}

enum APGIRadius {
  static let sm: CGFloat = 8  // alias for small
  static let small: CGFloat = 8
  static let md: CGFloat = 12  // alias for medium
  static let medium: CGFloat = 12
  static let lg: CGFloat = 16  // alias for large
  static let large: CGFloat = 16
  static let extraLarge: CGFloat = 20
}
