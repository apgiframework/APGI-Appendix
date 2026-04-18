import SwiftUI

struct MathematicalModelView: View {
  private let modelBody = """
    The Allostatic Precision-Gated Ignition Framework provides a quantitative framework for understanding the dynamics of conscious access. It integrates three core components—State Variables, Dynamics and Empirically Constrained Parameters—to capture the interplay between surprise accumulation, threshold adaptation and the probability of conscious ignition.

    State Variables
    The model employs three central state variables to represent the system's real-time state:

    * Precision-Weighted Surprise (Sₜ): This variable continuously accumulates incoming information, weighting prediction errors by their perceived reliability. It reflects the urgency and importance of sensory and interoceptive signals, determining whether they warrant conscious attention. Sₜ is a latent computational variable that must be inferred from neural and behavioral data (e.g. parietal ramping, pupil dilation, reaction times), not directly observed.

    * Dynamic Ignition Threshold (θₜ): A flexible threshold that adapts over time. For conscious access to occur, the accumulated surprise (Sₜ) must exceed this threshold which itself evolves based on recent activity and neurochemical modulation.

    * Time-Varying Precision (Πₑ(t) and Πᵢ(t)): These variables quantify the reliability of external sensory (exteroceptive) and internal bodily (interoceptive) information, respectively. They dynamically adjust the influence of prediction errors on surprise accumulation.

    The precision weights (Πₑ, Πᵢ) are dynamic variables whose evolution is governed on slower timescales by neuromodulatory control inputs, as formalized in the broader APGI Framework. For the purposes of simulating the core ignition circuit, they can be treated as parameters set by tonic neuromodulator concentrations ([ACh], [NE]).

    Surprise Accumulation
    The rate of change in precision-weighted surprise (Sₜ) depends on incoming prediction errors (ϵₑ(t), ϵᵢ(t)), weighted by their precision (Πₑ, Πᵢ), a natural decay rate (τ) and a noise term (σ·η(t)):
    dSₜ/dt = -Sₜ/τ + [ Πₑ · |εₑ(t)| + β · Πᵢ · |εᵢ(t)| ] + σ · η(t)

    Threshold Adaptation
    The evolution of the ignition threshold (θₜ) is shaped by its tendency to return to a baseline (θ₀), a transient post-ignition elevation (δ·B_{t-1}) and a term that lowers the threshold in response to rapidly increasing surprise (−λ·|dSₜ/dt|):
    dθₜ/dt = γ(θ₀ − θₜ) + δ·Bₜ₋₁ − λ·|dSₜ/dt|

    Ignition Probability
    The probability of conscious ignition (Bₜ) is determined by a sigmoid function (σ) of the difference between accumulated surprise and the current threshold, with α controlling the steepness of this transition:
    Bₜ = σ(α(Sₜ - θₜ))

    Empirically Constrained Parameters and Control Inputs
    The model's behavior is fine-tuned by parameters that define its characteristic time scales and sensitivities:
    τ ≈ 200 ms: Time constant for surprise decay.
    α ≈ 5–10: Controls the steepness of the ignition sigmoid switch.
    γ ≈ 2 s⁻¹: Rate of homeostatic recovery for the threshold.
    δ ≈ 0.3–0.5·θ₀: Magnitude of post-ignition threshold elevation (refractory effect).
    λ ≈ 0.1–0.3 (dimensionless): Sensitivity to urgency gain, scaling how rapidly increasing surprise lowers the threshold.
    β ≈ 1.2–1.5: Context-modulated somatic bias, weighting interoceptive signals more heavily.
    κ coefficients: Additional parameters specified in the full formalization.
    The system is further modulated by dynamic control inputs, including ongoing prediction errors (ϵₑ(t), ϵᵢ(t)), neuromodulator concentrations ([NE], [ACh], [5-HT], [DA]) and context/task variables that adjust parameters like β. These inputs ensure the model remains adaptive to both internal states and external demands.

    Parameters of the APGI Dynamical System for Simulation
    Parameter | Description | Empirical Constraint | Neural Implementation
    τ | Surprise decay time constant | ~200 ms | NMDA receptor decay, synaptic facilitation
    α | Sigmoid steepness (decision certainty) | 5–10 | Neural population gain in frontoparietal cortex
    γ | Threshold homeostatic recovery rate | ~2 s⁻¹ | Slow adaptive currents in thalamocortical circuits
    δ | Post-ignition refractory scalar | 0.3–0.5 · θ₀ | Short-term depression in thalamocortical loops
    λ | Urgency gain factor (dimensionless) | 0.1–0.3 | Phasic LC-NE response to surprise rate-of-change
    β | Somatic bias factor | 1.2–1.5 (neutral) | Ratio of LC-NE innervation density (AI/ACC vs. sensory)
    """

  var body: some View {
    EnhancedSectionView(section: self.enhancedSection)
  }

  private var enhancedSection: EnhancedSection {
    EnhancedSection(
      id: "mathematical-model",
      title: "Mathematical Model",
      summary:
        "A compact dynamical system for conscious ignition: surprise accumulates, a threshold adapts, and ignition probability emerges via a sigmoid switch under neuromodulatory control.",
      icon: Tab.mathematicalModel.icon,
      estimatedReadingTime: "~10 min",
      conceptDiagram: nil,
      subsections: [
        EnhancedSection.Subsection(
          id: "state-variables",
          title: "State Variables",
          content: self.extractParagraphs(
            startingAt: "State Variables",
            untilAnyOf: ["Surprise Accumulation", "Threshold Adaptation"], from: self.modelBody),
          category: .mathematical,
          hasDataTable: false
        ),
        EnhancedSection.Subsection(
          id: "surprise-accumulation",
          title: "Surprise Accumulation",
          content: self.extractParagraphs(
            startingAt: "Surprise Accumulation", untilAnyOf: ["Threshold Adaptation"],
            from: self.modelBody),
          category: .mathematical,
          hasDataTable: false
        ),
        EnhancedSection.Subsection(
          id: "threshold-adaptation",
          title: "Threshold Adaptation",
          content: self.extractParagraphs(
            startingAt: "Threshold Adaptation", untilAnyOf: ["Ignition Probability"],
            from: self.modelBody),
          category: .mathematical,
          hasDataTable: false
        ),
        EnhancedSection.Subsection(
          id: "ignition-probability",
          title: "Ignition Probability",
          content: self.extractParagraphs(
            startingAt: "Ignition Probability", untilAnyOf: ["Empirically Constrained Parameters"],
            from: self.modelBody),
          category: .mathematical,
          hasDataTable: false
        ),
        EnhancedSection.Subsection(
          id: "parameters-table",
          title: "Parameters (Table)",
          content: self.extractParagraphs(
            startingAt: "Parameters of the APGI Dynamical System for Simulation", untilAnyOf: [],
            from: self.modelBody),
          category: .mathematical,
          hasDataTable: true
        ),
      ],
      relatedSections: [.apgiMapping, .parameterIdentifiability, .neuromodulatoryControl]
    )
  }

  private func extractParagraphs(
    startingAt marker: String, untilAnyOf endMarkers: [String], from text: String
  ) -> String {
    let lines = text.components(separatedBy: "\n")
    guard
      let startIndex = lines.firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces).hasPrefix(marker)
      })
    else {
      return text
    }

    var collected: [String] = []
    var i = startIndex
    while i < lines.count {
      let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
      if i != startIndex, !endMarkers.isEmpty, endMarkers.contains(where: { trimmed.hasPrefix($0) })
      {
        break
      }
      collected.append(lines[i])
      i += 1
    }

    return collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

#Preview {
  MathematicalModelView()
}
