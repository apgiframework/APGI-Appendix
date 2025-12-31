import SwiftUI

struct EpistemicStandardsView: View {
    private let standardsBody = """

Claim Type | Required Evidence | APGI Status

Level 1: "APGI is metabolically efficient" | Measured J/K during conscious vs. unconscious; comparison to alternatives | Not done

Level 2: "APGI is information-efficient" | Calculate mutual information, compare to channel capacity | Plausible, incompletely validated

Level 3: "APGI minimizes free energy" | Show neural dynamics implement gradient descent on F | Some support, contested

Cross-Level: "Variational efficiency → thermodynamic efficiency" | Quantitative bridge calculation | Critical gap

Strong Claim: "APGI is thermodynamically necessary" | Prove all alternatives violate physics or use more energy | Unsupported

Moderate Claim: "APGI is thermodynamically probable" | Show convergent evolution, adaptive value, efficiency arguments | Plausible but incomplete

Weak Claim: "APGI describes neural mechanisms" | Demonstrate biological implementations match computational functions | Well-supported

Comparative Frameworks: GNWT, IIT, Re-entry theories | Share Level-1 thermodynamic gaps: invoke energy costs and dissipation without measured Joules/Kelvin or Landauer comparisons; APGI's explicit bridges and standards distinguish it methodologically. | Well-supported


"""

    var body: some View {
        EnhancedContentCard(
            title: "Epistemic Standards",
            content: standardsBody,
            category: .theoretical,
            hasDataTable: true
        )
        .padding()
    }
}

#Preview {
    EpistemicStandardsView()
}
