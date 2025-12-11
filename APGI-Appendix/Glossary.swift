import SwiftUI

struct GlossaryView: View {
    var body: some View {
        ScrollView {
            Text("""
Glossary

Active Inference

An action selection strategy that minimizes expected free energy by selecting policies that balance goal-directed (pragmatic) and information-seeking (epistemic) values. It is the primary mechanism for resolving uncertainty that cannot be handled by perception alone.

Allostasis

The process of anticipatory, predictive regulation of the internal milieu to maintain physiological stability through change. It is the primary function driving the APGI Framework's somatic bias, as the brain proactively defends the body's viability, making interoceptive threats potent triggers for conscious ignition.

Attention

A neuromodulatory process that selectively enhances the precision (inverse variance, reliability) of specific sensory or cognitive signals. In the APGI Framework, attention is mechanistically implemented by acetylcholine (for exteroceptive precision, Πₑ) and norepinephrine (for interoceptive precision, Πᵢ), thereby prioritizing signals for processing and potential conscious access.

Bayesian Inference

A normative framework for updating beliefs (posteriors) about hidden states by combining prior knowledge with new evidence (likelihood), weighted by its precision.

Conscious Access

The global availability of information for verbal report, reasoning, long-term memory encoding and flexible behavioral control. This is the primary explanatory target of the APGI Framework, formally modeled as the outcome of a precision-gated ignition process. It is considered functionally and potentially phenomenally distinct from fringe or unreportable states.

Criticality

A state of a dynamical system poised at a phase transition between order and disorder, often characterized by power-law statistics and optimal computational properties. The APGI Framework proposes that the brain operates near criticality and the ignition transition shares features of a critical bifurcation.

E/I Balance (Excitation/Inhibition Balance)

The dynamic equilibrium between excitatory and inhibitory neural activity, critical for stable network function. The APGI Framework specifies that ignition involves a transient, localized shift in this balance where recurrent excitation in thalamocortical loops overcomes local inhibition (e.g., from parvalbumin-positive interneurons) to enable a metastable, high-firing attractor state.

Exteroception

Sensing of the external world through vision, audition, somatosensation, taste and smell. In the APGI Framework, exteroceptive signals generate prediction errors (εₑ) that are weighted by exteroceptive precision (Πₑ), typically modulated by acetylcholine.

Expected Free Energy

A quantity in active inference that is minimized through policy selection. It balances the expected cost of being in a future state (pragmatic value) and the information gain expected from a future state (epistemic value).

Fading Memory

The exponential decay of information retention over time, reflecting the gradual loss of trace strength in neural representations. Timescale measured as the decay constant (τ) in behavioral or neural data, fitted to an exponential function of the form e^(-t/τ) where t is time and τ is the characteristic decay time, often estimated from delayed-match-to-sample tasks or neural adaptation paradigms.

Free Energy Principle

A theoretical framework stating that self-organizing systems act to minimize an information-theoretic quantity called variational free energy which is an upper bound on surprise. The APGI Framework adopts the FEP as a guiding heuristic for understanding perception and action but remains agnostic about its strongest metaphysical claims.

Generative Model

The brain's internal model of the causal structure of the world and the body. It generates predictions about sensory inputs and is updated via prediction errors. The APGI Framework posits a hierarchical generative model with segregated but interacting exteroceptive and interoceptive streams.

Global Ignition

A non-linear, all-or-none transition (typically unfolding over ~300-500ms) in which a sufficiently strong, precision-weighted surprise signal (Sₜ > θₜ) triggers widespread, sustained and recurrent activation across frontoparietal and thalamocortical networks.

Global Workspace

A theoretical architecture proposing a brain-wide broadcasting system that makes information globally accessible to specialized processors. The APGI Framework embeds the GNW within a predictive, metabolic and embodied architecture, providing a normative mechanism (precision-weighted surprise) for which contents gain access to the workspace.

Hierarchical Predictive Coding

A neural implementation of Bayesian inference where prediction errors propagate up a cortical hierarchy to update beliefs while predictions propagate down to explain away sensory data. The APGI Framework uses this as its core computational architecture.

Homeostasis

A reactive process by which biological systems maintain internal stability through negative feedback mechanisms that correct deviations after they occur (e.g., shivering when cold). Contrasted with the predictive, proactive nature of allostasis.

Ignition

A rapid, nonlinear phase transition in large-scale network activity, marking the transition from local to global information broadcasting. Operationalized as the sudden increase in synchronized gamma-band oscillations (30–100 Hz) across frontoparietal networks, detectable via EEG/MEG coherence metrics or intracranial recordings during stimulus detection tasks.

Ignition Threshold (θₜ)

A dynamic, metabolically-gated barrier that precision-weighted surprise (Sₜ) must exceed to trigger global ignition. It is not static but adapts based on recent conscious events (post-ignition refractory period), urgency and baseline neuromodulatory tone (e.g., lowered by NE, raised by 5-HT).

Integrated Information Theory (IIT)

A theory of consciousness that posits consciousness is identical to a system's integrated information (Φ), a measure of the irreducibility of its causal structure. The APGI Framework is potentially compatible with IIT, proposing that ignition events may be a primary generator of high-Φ states in the brain, but treats this as a correlation rather than an identity.

Interoception

The sense of the internal state of the body, including visceral, cardiovascular, respiratory and metabolic signals. In the APGI Framework, interoceptive prediction errors (εᵢ) are assigned a baseline priority (somatic bias, β) and weighted by interoceptive precision (Πᵢ), typically modulated by norepinephrine, making them potent drivers of conscious access.

Landauer's Principle

Fundamental limit stating that erasing one bit of information requires dissipating at least k B T ln(2) energy as heat

Markov Blanket

Statistical boundary separating internal states of a system from external states, defining an organism's interface with the environment.

Metastability

A dynamic regime in which neural assemblies transiently synchronize and desynchronize, maintaining a balance between integration and segregation. This balance is essential for the global workspace's operation, as it allows the system to remain in a sub-threshold state until precision-weighted surprise pushes it across the ignition threshold into a transiently synchronized global state.

Phenomenal Consciousness

The subjective, qualitative aspect of experience (qualia)—what it is like to see red, feel pain or be oneself. The APGI Framework deliberately brackets the "hard problem" of explaining phenomenal consciousness, focusing instead on providing a sufficient mechanism for access consciousness while acknowledging they typically co-occur.

Phenomenal Unity

The property of conscious experience whereby multiple contents (sensory, emotional, cognitive) are bound into a single, coherent field of awareness.

Precision (Π)

The inverse variance (1/σ²) of a probability distribution; in neural terms, it corresponds to the confidence or reliability assigned to a prediction or a prediction error signal. It is dynamically modulated by neuromodulators (ACh, NE) and implements a mechanistic, Bayesian form of attention. The degree of gain modulation applied to prediction errors, reflecting the relative weighting of sensory evidence in updating internal models. Measured as the amplitude scaling factor of prediction error units in neural responses, often quantified through electrophysiological or fMRI signal variability analysis.

Prediction Error (ε)

The mismatch between a sensory input (exteroceptive or interoceptive) and the brain's top-down prediction. It is the fundamental signal that drives learning, belief updating and when sufficiently precision-weighted, can trigger conscious access. The neural response generated by a mismatch between expected and actual sensory input. Measured as the difference in firing rates, EEG/MEG signal amplitudes or BOLD signal deviations between predicted and observed stimuli, typically standardized to baseline activity levels.

Precision-Weighted Surprise (Sₜ)

The key driving variable in the APGI Framework. It is the accumulated sum of exteroceptive and interoceptive prediction errors, each scaled by their respective precision (Sₜ = Πₑ·|εₑ| + β·Πᵢ·|εᵢ|). This quantity is compared against the ignition threshold (θₜ) to determine conscious access.

Self-Model

The brain's dynamic, multi-layered representation of the organism as a persistent, embodied agent. In the APGI Framework, this is implemented through hierarchical generative models that track the body as an object in the world and as the source of a first-person perspective.

Self-Model Coherence

The degree to which the self-model maintains temporal and structural consistency; proposed as a neural substrate for phenomenal unity.

Somatic Marker

A learned association, formalized in the APGI Framework as a probability distribution (M_{c,a}), that links specific contexts and actions to anticipated interoceptive outcomes. Retrieved by the vmPFC-hippocampal system, somatic markers dynamically bias interoceptive precision (Πᵢ), making us hypersensitive to bodily signals in threatening or significant situations.

Surprise

The negative log probability of an observation given a model. The brain minimizes a bound on surprise (variational free energy) through perception, learning and action.

Thermodynamic Costs

The metabolic energy required for neural processes. The APGI Framework emphasizes that global ignition is metabolically expensive and involves NMDA activation, sustained firing, neuromodulator release which provides the evolutionary rationale for a dynamic ignition threshold—consciousness is deployed only when benefits outweigh costs.

Threshold (θₜ)

The critical point at which a stimulus or prediction error triggers a detectable neural or behavioral response. Psychometrically measured as the stimulus intensity or signal-to-noise ratio at which performance reaches a predefined criterion (e.g., 75% detection accuracy), derived from psychometric curves or adaptive staircase procedures.

Workspace Capacity

The limited amount of information that can be simultaneously maintained in the global workspace. This capacity is constrained by the winner-take-all nature of the ignition process and the post-ignition refractory period (elevated θₜ) which underlies phenomena like the attentional blink.
""")
            .font(.body)
            .padding()
        }
        .padding()
    }
}

#Preview {
    GlossaryView()
}
