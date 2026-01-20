import SwiftUI

struct NeuromodulatorEffectsView: View {
    private let effectsBody = """

Neuromodulator Effects on APGI Model State Variables

Neuromodulators act as slow control inputs that reconfigure the APGI system's operational regime by
modulating precision weights (Πₑ, Πᵢ) and ignition threshold (θₜ). Their effects are receptor-specific,
circuit-selective and temporally multiplexed (tonic vs. phasic). Crucially, they do not act in isolation
but interact dynamically such as NE and ACh jointly shape signal-to-noise during threat while DA and
5-HT balance exploration vs. stability.

Norepinephrine [NE]

Norepinephrine prepares the system for rapid, critical action by amplifying the urgency of relevant
signals. Its effects are not uniform but instead reflect the locus coeruleus (LC)'s topographic projection
architecture, producing distinct functional outcomes depending on innervation density—high in regions
like the anterior insula (AI) and anterior cingulate cortex (ACC), but low in areas such as the primary
visual cortex (V1).

Baseline Threshold (θ₀) and Urgency Gating
Norepinephrine lowers the baseline threshold (θ₀) with a coupling constant (κ_NE) of approximately
0.25–0.35. Phasic LC bursts activate α₁/β-receptors on pyramidal neurons in the AI and ACC, increasing
cortical excitability and suppressing the thalamic reticular nucleus (TRN). This reduces the effective
threshold (θₜ), thereby lowering the evidence required for ignition during threat or surprise—such as
predator detection. The result is rapid access to the cognitive workspace for survival-relevant content.

Interoceptive Precision (Πᵢ) and Soma-Bias Amplification
Norepinephrine boosts interoceptive precision through dense LC projections to the AI and ACC where
β-receptors on insular pyramidal neurons enhance the gain for bodily prediction errors. This soma-bias
amplification prioritizes internal signals—such as heart rate or pain—over external stimuli during
arousal. It explains why sensations like pain or dyspnea dominate conscious awareness under stress.

Somatic Bias (β) and Contextual Reprioritization
Under threat, norepinephrine dynamically increases somatic bias (β), with values rising to 2–5. This
gain is topographically biased toward interoceptive hubs (AI/ACC) rather than sensory cortices. As a
result, even mild interoceptive deviations exceed the threshold (θₜ) while exteroceptive inputs are
filtered unless directly relevant to survival.

Acetylcholine [ACh]

Acetylcholine (ACh) modulates learning by signaling expected uncertainty—indicating that the
environment is changing but remains learnable. This role is distinct from norepinephrine (NE) which
signals unexpected uncertainty or threat.

Exteroceptive precision (Πₑ)
ACh enhances exteroceptive precision (Πₑ) through projections from the basal forebrain (BF) to the
sensory cortex. These projections activate M1 muscarinic and nicotinic acetylcholine receptors (nAChRs),
increasing pyramidal neuron excitability and disinhibiting PV+ interneurons. ACh differentially modulates
interneuron subtypes, with net effect of sharpening cortical tuning and improving signal-to-noise ratio
through coordinated action on pyramidal cells and interneurons. The result is an improved signal-to-noise
ratio, sharpening sensory processing. This sensory sharpening heightens the reliability of external
prediction errors, particularly in volatile yet learnable contexts, such as navigating a new city.

Baseline threshold (θ₀)
The baseline threshold (θ₀) is modestly lowered (κ_ACh ≈ 0.10–0.20) as M1-mediated depolarization
reduces the spike threshold in layer 5 neurons. This adjustment optimizes learning by selectively
facilitating plasticity, enabling rapid model updates. Importantly, the threshold is lowered just enough
to allow only novel, informative stimuli into the cognitive workspace—specifically those encountered
in volatile contexts, rather than all stimuli indiscriminately.

Surprise accumulation (f(·))
ACh influences surprise accumulation (f(·)) by enhancing divisive normalization. It sharpens neural
tuning curves, improving competition among neural coalitions. This mechanism ensures that only the most
informative external surprises ignite, thereby preventing cognitive overload and supporting selective
attention.

Serotonin [5-HT]

Serotonin (5-HT) modulates cognitive processes through distinct, receptor-dependent mechanisms that
target specific aspects of neural function and hierarchical information processing. A critical nuance is
that serotonin's effects are both state- and receptor-dependent. Rather than acting as a simple inhibitory
neurotransmitter, it modulates the precision hierarchy within neural networks, not merely overall
excitability.

Baseline Threshold (θ₀)
At baseline, serotonin elevates the threshold (θ₀) for neural ignition (κ_5HT ≈ 0.35–0.50). By
activating 5-HT₁ₐ receptors, it increases potassium (K⁺) conductance, hyperpolarizing pyramidal
neurons—particularly in layer 5. This raises the input required for ignition, enforcing stability by
suppressing spurious activations in safe or predictable contexts, such as routine tasks. As a result, it
reduces false alarms associated with anxiety.

Hierarchical Precision
Serotonin's influence on hierarchical precision varies by receptor type. Activation of 5-HT₂ₐ receptors
diminishes confidence in top-down priors, allowing low-level sensory content to drive ignition—a
mechanism observed with psychedelics. In contrast, 5-HT₁ₐ receptors enhance confidence in high-level
priors, effectively suppressing perceptual noise. This dual role—stabilizing beliefs via 5-HT₁ₐ and
relaxing them via 5-HT₂ₐ—aligns with the REBUS (Relaxed Beliefs Under Psychedelics) model. It explains
why selective serotonin reuptake inhibitors (SSRIs) alleviate anxiety while psychedelics induce ego
dissolution.

Post-Ignition Refractoriness (δ)
Following ignition, serotonin potentiates post-ignition refractoriness (δ) by enhancing inhibition which
prolongs the recovery period. This cognitive filtering prevents rapid re-ignition, supporting sustained
focus and attentional control.

Dopamine [DA]

Dopamine (DA) functions as a value signal for adaptive resource allocation, dynamically adjusting
cognitive and motivational processes through distinct tonic and phasic mechanisms. This involves ventral
striatum outputs modulating ACC activity which in turn influences LC-NE release, creating a polysynaptic
loop that integrates value with bodily state. A critical nuance lies in dopamine's bidirectional effects:
tonic activity raises θₜ to stabilize the system while phasic activity selectively lowers the effective
threshold for salient content. This duality clarifies the paradox observed in schizophrenia where
hallucinations (over-ignition of irrelevant noise) coexist with avolition (under-ignition of meaningful
goals). Through these mechanisms, dopamine shapes how the brain prioritizes and responds to meaningful
stimuli.

Baseline threshold (θ₀)
In safe or stable contexts, the baseline threshold (θ₀) increases, with tonic dopamine activating D2
receptors on cortical interneurons. This enhances inhibition of layer 5 basal dendrites, raising the
threshold (θₜ) and promoting resource conservation. By suppressing the activation of non-goal-relevant
content—such as filtering out distractions during a meal—this mechanism helps maintain focus in
rewarding or stable environments.

Precision for Salient Errors
For precision in detecting salient errors, dopamine operates phasically. Phasic dopamine bursts activate
D1 receptors, amplifying NMDA currents in the prefrontal cortex (PFC) and striatum. This heightens the
gain for reward-prediction errors, ensuring that unexpected rewards or their omissions receive elevated
salience (Π). As a result, these events trigger updates to value models, refining the brain's predictive
accuracy.

Somatic bias (β)
Dopamine indirectly influences somatic bias (β) by acting on the ventral striatum which modulates the
anterior cingulate cortex (ACC) and norepinephrine (NE) release. This interaction bridges homeostatic
needs—such as hunger or thirst—with incentive salience, elevating the salience (Πᵢ) of motivationally
relevant stimuli.



"""

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                EnhancedContentCard(
                    title: "Neuromodulator Effects",
                    content: effectsBody,
                    category: .biological,
                    hasDataTable: false
                )
            }
            .padding()
        }
    }
}

#Preview {
    NeuromodulatorEffectsView()
}
