import SwiftUI

extension Color {
    static let apgiBlue = Color(hue: 0.55, saturation: 0.6, brightness: 0.9)
    static let apgiPurple = Color(hue: 0.75, saturation: 0.5, brightness: 0.85)
    static let apgiGreen = Color(hue: 0.35, saturation: 0.5, brightness: 0.8)
    static let apgiOrange = Color(hue: 0.08, saturation: 0.7, brightness: 0.95)
    static let apgiRed = Color(hue: 0.98, saturation: 0.6, brightness: 0.9)
}

enum APGITypography {
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleLarge = Font.system(size: 28, weight: .bold)
    static let titleMedium = Font.system(size: 22, weight: .semibold)
    static let bodyLarge = Font.system(size: 17)
    static let bodyMedium = Font.system(size: 15)
    static let captionLarge = Font.system(size: 13)
    static let captionSmall = Font.system(size: 11)
}

enum APGISpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

enum APGIRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}
