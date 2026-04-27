import SwiftUI

extension Color {
  // Neural Glow Semantics (Light Theme)
  static let thresholdBlue = Color(hex: "#0066CC") ?? Color.blue
  static let precisionRed = Color(hex: "#CC0033") ?? Color.red
  static let errorYellow = Color(hex: "#CC9900") ?? Color.yellow
  static let workspacePurple = Color(hex: "#6633CC") ?? Color.purple
  static let neuromodGreen = Color(hex: "#008866") ?? Color.green
  static let inactiveSlate = Color(hex: "#6B7280") ?? Color.gray
  static let spaceBlack = Color(hex: "#FFFFFF") ?? Color.white
  static let darkNavy = Color(hex: "#F3F4F6") ?? Color(white: 0.95)

  // Legacy mappings for compatibility (aliased to brand colors)
  static let apgiBlue = thresholdBlue
  static let apgiPurple = workspacePurple
  static let apgiGreen = neuromodGreen
  static let apgiOrange = errorYellow
  static let apgiRed = precisionRed

  // Semantic Colors (Mapped to Neural Glow)
  static let apgiSuccess = neuromodGreen
  static let apgiWarning = errorYellow
  static let apgiDanger = precisionRed
  static let apgiInfo = thresholdBlue

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
    if self == .thresholdBlue { return "#0066CC" }
    if self == .precisionRed { return "#CC0033" }
    if self == .errorYellow { return "#CC9900" }
    if self == .workspacePurple { return "#6633CC" }
    if self == .neuromodGreen { return "#008866" }
    if self == .spaceBlack { return "#FFFFFF" }
    if self == .darkNavy { return "#F3F4F6" }
    return nil
  }
}

enum APGITypography {
  // Headlines & Titles (Crimson Pro)
  static let display = Font.custom("CrimsonPro-Bold", size: 72)
  static let h1 = Font.custom("CrimsonPro-Bold", size: 48)
  static let h2 = Font.custom("CrimsonPro-SemiBold", size: 30)

  // Body, Labels, Captions (Inter)
  static let h3 = Font.custom("Inter-SemiBold", size: 20)
  static let body = Font.custom("Inter-Regular", size: 16)
  static let label = Font.custom("Inter-Medium", size: 14)
  static let caption = Font.custom("Inter-Regular", size: 14)
  static let micro = Font.custom("Inter-Regular", size: 12)

  // Monospace (Fira Code)
  static let mono = Font.custom("FiraCode-Regular", size: 14)

  // Fallbacks for when fonts aren't loaded in environment
  static func systemHeadline(size: CGFloat) -> Font {
    .system(size: size, weight: .bold, design: .serif)
  }

  static func systemBody(size: CGFloat) -> Font {
    .system(size: size, weight: .regular, design: .default)
  }
}

enum APGISpacing {
  static let unit: CGFloat = 8

  static let xs = unit * 0.5 // 4px
  static let sm = unit       // 8px
  static let md = unit * 2   // 16px
  static let lg = unit * 3   // 24px
  static let xl = unit * 4   // 32px
  static let xxl = unit * 6  // 48px
  static let xxxl = unit * 8 // 64px
  static let giant = unit * 12 // 96px

  // Contextual Spacing
  static let cardPadding: CGFloat = 24
  static let sectionSpacing: CGFloat = 96
  static let componentSpacing: CGFloat = 48
  static let elementSpacing: CGFloat = 24
}

enum APGIRadius {
  static let standard: CGFloat = 12
}
