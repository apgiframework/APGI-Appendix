import SwiftUI

struct APGIStatementView: View {
  private let statementBody = """

    Consciousness emerges as an adaptive inference protocol—a metabolically expensive, allostatically gated control system that prioritizes survival-relevant computations under energy constraints. Far from being an introspective luxury or philosophical epiphenomenon, it functions as a precision-tuned motivation and steering system that compels organisms to prioritize immediate threats to viability: energy deficits, physical danger, social exclusion, and reproductive opportunities. Over evolutionary time, this alignment with inclusive fitness was sculpted into phenotypic steering. The felt quality of experience—the pain of hunger, the urgency of thirst, the warmth of social connection—serves as the user interface of this survival engine, making organisms behave in ways that propagate the genes that built them. Consciousness thus operates not for the organism's inner life but to make survival-relevant outcomes consciously salient when energetically cheaper mechanisms prove insufficient.

    This system is energetically rationed rather than continuously active, igniting only when precision-weighted prediction errors—particularly those signaling homeostatic or energetic threat—exceed a dynamic, resource-dependent threshold. Empirical evidence confirms its cost: conscious processing consumes twenty to thirty percent more glucose and ATP than unconscious processing, while anesthesia reduces whole-brain metabolism by forty to fifty percent. The P3b EEG signature reveals consciousness as discrete five-hundred-millisecond ignition events rather than a continuous stream, demonstrating its conditional deployment.

    From a thermodynamic perspective, consciousness operates like a biological heat engine. It doesn't produce awareness as an end-state but uses awareness as a control signal to enable actions that import low-entropy energy and export entropy, thereby staving off thermodynamic decay. Maintaining coherent, low-entropy conscious states requires continuous energy dissipation. Consciousness exists not for its own sake but as an evolutionary solution to maintaining low-entropy states in high-entropy environments. While the subjective feel of this interface presents the so-called hard problem, its functional role in prioritization and learning is what matters for survival and is fully explicable within this framework.

    While energy acquisition provides the core selective pressure, the content and scope of consciousness extend far beyond immediate caloric need. It scaffolds social coordination, long-term planning, and exploratory behavior—all of which enhance survival in complex, cooperative niches. Yet even these higher functions ultimately serve energetic ends: social alliances buffer against resource scarcity, delayed gratification enables temporal entropy smoothing such as fasting now to hunt later, and cultural transmission reduces the metabolic cost of individual learning. Consciousness is therefore not about calorie counting but represents the adaptive architecture that evolved because organisms who could dynamically reconfigure behavior in response to energetic uncertainty outcompeted those who could not. This reframes consciousness from mysterious inner experience to adaptive control architecture—thermodynamically expensive, conditionally deployed, evolutionarily explicable, and empirically testable.

    """

  var body: some View {
    EnhancedContentCard(
      title: "APGI Statement about Consciousness",
      content: self.statementBody,
      category: SectionCategory.theoretical,
      hasDataTable: false
    )
    .padding(APGISpacing.lg)
  }
}

#Preview {
  APGIStatementView()
}
