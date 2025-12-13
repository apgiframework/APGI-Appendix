import SwiftUI

struct ApgiToCognitiveView: View {
    var body: some View {
        ScrollView {
            Text("""

APGI Parameters → Cognitive Constructs

Parameter | Associated Cognitive Constructs | Mechanics

θ₀ (Baseline Ignition Threshold) | Cognitive Load Capacity, Energy Conservation Mode, Distractibility (inverse), Concentration Capacity, Motivational Readiness, Flexibility, Certainty Tolerance, Rumination Resistance, Mind-Wandering Propensity (inverse) | Sets the "hurdle height" for conscious access; modulated by adenosine (fatigue), orexin (arousal), tonic DA (expected value) and 5-HT₁ₐ (stability)

Πₑ (Exteroceptive Precision) | Sensory Awareness, External Attention Gain, Perceptual Learning Rate, Environmental Error Detection, Perceptual Discrimination, Sensory Overload Vulnerability, Predictive Coding Efficiency (external domain) | Controlled primarily by ACh (nicotinic/muscarinic); reflects confidence in external sensory signals

Πᵢ (Interoceptive Precision) | Interoceptive Awareness, Emotional Intensity, Somatic Marker Strength, Empathy (affective component), Body-Mind Connection, Stress Resilience (context-dependent), Gut Feelings, Affective Bias Sensitivity | Controlled primarily by NE (α₁/β receptors); reflects confidence in bodily signals; anatomically biased toward insula-ACC

β (Soma-Bias Factor) | Body-Prioritization, Introversion-Extroversion (partial), Private Self-Consciousness, Somatization Tendency, Internal vs External Locus, Stress Response Style | Estimated ~1.2-1.5 baseline; reflects evolutionary/architectural prioritization of interoceptive signals

Sₜ (Surprise Accumulation) | Novelty Detection, Salience, Alertness, Orienting Response, Unexpectedness Sensitivity | Real-time integration of Π-weighted prediction errors; determines proximity to threshold

dSₜ/dt (Rate of Surprise Change) | Urgency Perception, Time Pressure Sensitivity, Threat Imminence, Flow State Dynamics, Looming Stimulus Detection | Drives λ-mediated threshold lowering; explains "faster-than-expected" conscious access under threat
""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    ApgiToCognitiveView()
}
