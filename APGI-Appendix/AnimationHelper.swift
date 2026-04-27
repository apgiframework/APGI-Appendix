import SwiftUI

// MARK: - Animation Helper

enum AnimationHelper {
  static func animated(_ animation: Animation? = nil) -> Animation? {
    if ThemeManager.shared.enableAnimations {
      return animation ?? .easeInOut(duration: APGISimulatorConstants.animationDuration)
    } else {
      return nil
    }
  }

  static func transition(_ transition: AnyTransition? = nil) -> AnyTransition {
    if ThemeManager.shared.enableAnimations {
      return transition
        ?? .opacity.combined(with: .scale(scale: APGISimulatorConstants.transitionScale))
    } else {
      return .identity
    }
  }
}

// MARK: - Animated View Modifier

struct AnimatedModifier: ViewModifier {
  let animation: Animation?
  let transition: AnyTransition?

  init(animation: Animation? = nil, transition: AnyTransition? = nil) {
    self.animation = animation
    self.transition = transition
  }

  func body(content: Content) -> some View {
    content
      .animation(
        AnimationHelper.animated(self.animation), value: ThemeManager.shared.enableAnimations
      )
      .transition(AnimationHelper.transition(self.transition))
  }
}

// MARK: - View Extensions

extension View {
  func animatedTransition(_ transition: AnyTransition? = nil, animation: Animation? = nil) -> some View {
    self.modifier(AnimatedModifier(animation: animation, transition: transition))
  }

  func conditionalAnimation(_ condition: Bool, animation: Animation? = nil) -> some View {
    self.modifier(ConditionalAnimationModifier(condition: condition, animation: animation))
  }
}

struct ConditionalAnimationModifier: ViewModifier {
  let condition: Bool
  let animation: Animation?

  func body(content: Content) -> some View {
    if self.condition {
      content.animation(AnimationHelper.animated(self.animation), value: UUID())
    } else {
      content
    }
  }
}
