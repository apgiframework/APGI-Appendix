import SwiftUI

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
}
