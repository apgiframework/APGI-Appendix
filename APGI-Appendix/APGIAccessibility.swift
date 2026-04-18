import SwiftUI

// MARK: - Accessibility Models

struct AccessibilityPreferences {
  let colorBlindMode: ColorBlindMode
  let highContrastEnabled: Bool
  let reducedMotionEnabled: Bool
  let hapticFeedbackEnabled: Bool

  static let `default` = AccessibilityPreferences(
    colorBlindMode: .none,
    highContrastEnabled: false,
    reducedMotionEnabled: false,
    hapticFeedbackEnabled: true
  )
}

enum ColorBlindMode {
  case none
  case protanopia
  case deuteranopia
  case tritanopia
}

// MARK: - View Extensions

extension View {
  func apgiAccessibility(
    label: String,
    hint: String? = nil,
    value: String? = nil,
    traits: AccessibilityTraits = []
  ) -> some View {
    self
      .accessibilityLabel(Text(label))
      .accessibilityHint(hint.map(Text.init) ?? Text(""))
      .accessibilityValue(value.map(Text.init) ?? Text(""))
      .accessibilityAddTraits(traits)
  }

  func enhancedAccessibility<T: Equatable>(
    dynamicLabel: String,
    currentValue: String? = nil,
    contextualHint: String? = nil,
    primaryAction: (() -> Void)? = nil,
    userPreferences: AccessibilityPreferences = .default,
    significantEvent: T? = nil
  ) -> some View {
    let baseView =
      self
      .accessibilityElement(children: .combine)
      .accessibilityLabel(dynamicLabel)
      .accessibilityValue(currentValue ?? "")
      .accessibilityHint(contextualHint ?? "")
      .accessibilityInputLabels(["activate", "select", "choose"])
    // Honor user's system dynamic type settings - do not force a specific size

    let accessibilityView =
      baseView
      .applyIf(primaryAction != nil) { view in
        view.accessibilityAction(.default) {
          primaryAction?()
        }
      }

    let preferenceView =
      accessibilityView
      .colorBlind(mode: userPreferences.colorBlindMode)
      .highContrast(enabled: userPreferences.highContrastEnabled)

    return
      preferenceView
      .applyIf(userPreferences.hapticFeedbackEnabled && significantEvent != nil) { view in
        view.sensoryFeedback(.impact, trigger: true)
      }
  }

  func colorBlind(mode: ColorBlindMode) -> some View {
    Group {
      switch mode {
      case .none:
        self
      case .protanopia:
        self.opacity(0.8).saturation(0.7)
      case .deuteranopia:
        self.opacity(0.8).saturation(0.6)
      case .tritanopia:
        self.opacity(0.8).saturation(0.5)
      }
    }
  }

  func highContrast(enabled: Bool) -> some View {
    Group {
      if enabled {
        self
          .background(Color.black)
          .foregroundColor(Color.white)
          .colorScheme(.dark)
      } else {
        self
      }
    }
  }
}

// MARK: - Helper Extensions

extension View {
  @ViewBuilder
  func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
