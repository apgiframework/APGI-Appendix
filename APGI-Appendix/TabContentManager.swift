import SwiftUI
struct TabContentView: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var body: some View {
        Group {
            if tab == .glossary {
                GlossaryView()
            } else if tab == .bibliography {
                BibliographyView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: tab.icon)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                        
                        Text(tabContentText(for: tab))
                            .font(.body)
                            .padding()
                    }
                    .padding()
                }
            }
        }
    }
    
    private func tabContentText(for tab: Tab) -> String {
        switch tab {
case .methodology:
            return """
The persistent challenges in the field are the pitfalls of vague assertions, implicit assumptions and unfalsifiable claims that have long hindered progress. Theoretical frameworks of consciousness must meet stringent standards to move beyond correlation and establish causation, ensure falsifiability and enable comparative analysis. To advance consciousness science, we propose seven criteria for theoretical frameworks, each ensuring that theories remain empirically grounded, logically rigorous and scientifically testable.

Standard 1: Level Transparency
Every theoretical claim must be explicitly tagged by its analytical level, preventing implicit cross-level inferences and clarifying which evidence supports which claims. Level 1 (Thermodynamic) focuses on energy, entropy and physical costs, requiring measurements in joules or kelvin. Level 2 (Information-Theoretic) addresses bits, mutual information and channel capacity, necessitating information-theoretic calculations. Level 3 (Computational) examines algorithms and neural mechanisms, demanding circuit- or molecular-level evidence.

Standard 2: Bridge Principles Required
Cross-level claims must specify the mathematical or physical principles that connect them, making inferential leaps explicit and identifying where theories rely on unproven assumptions. For example, moving from Level 3 to Level 2 requires showing that variational inference maximizes information through formal proof. Linking Level 2 (information operations) to Level 1 (energy costs) necessitates quantitative calculations via Landauer's principle. Demonstrating that Level 3 computational mechanisms minimize energy therefore requires integrating the proofs and calculations of both \\(3 \\to 2\\) and \\(2 \\to 1\\) connections.

Standard 3: Quantitative Benchmarks
Claims of efficiency or optimality must provide specific, measurable metrics, preventing vague assertions and enabling rigorous comparative analysis. "Thermodynamically efficient" demands comparing energy expenditure per event (e.g., in joules) to alternative models. "Information-optimal" requires calculating mutual information relative to channel capacity. "Computationally fast" necessitates measuring reaction times against competing explanations.

Standard 4: Falsification Conditions
Theories must state clear, explicit conditions under which they would be falsified, protecting against unfalsifiable theories and guiding critical experiments. At the level-specific stage, this means defining the evidence that would falsify thermodynamic, information-theoretic or computational claims. At the framework level, theories must specify evidence that would falsify the entire theory, with no ambiguous accommodations for surprising results.

Standard 5: Alternative Comparison
Theories must compare their predictions to at least two alternative frameworks, preventing self-confirming evidence and driving critical experimental design. The theory must specify how each alternative explains the same phenomena, identify predictions that differentiate among the frameworks and design experiments capable of distinguishing them.

Standard 6: Evolutionary Plausibility
Theories must address why evolution would select the proposed mechanisms through constraint-driven analysis, identifying the physical or biological constraints that shaped the mechanism. The theory must explain the adaptive value and fitness advantage it provides, determine if independent lineages evolved similar solutions (convergence) and justify why simpler alternatives were not selected. Mechanisms requiring unlikely mutations or offering no adaptive advantage are implausible, even if empirically supported.

Standard 7: Causal Roadmap
Since most consciousness evidence remains correlational, theories must outline an experimental path from correlation to causation in five explicit stages. First, correlation establishes that \\\\text{X} and consciousness co-occur. Second, Manipulation shows that altering \\\\text{X} changes consciousness. Third, Mechanism defines the pathway from \\\\text{X} to consciousness. Fourth, Necessity demonstrates that blocking the pathway abolishes \\\\text{X}'s effect. Fifth, Sufficiency proves that \\\\text{X} alone can produce consciousness which is the most stringent test. This ensures causal claims are explicitly tested rather than merely assumed.
"""
        case .mathematicalModel:
            return """
Mathematical Model
The Allostatic Precision-Gated Ignition Framework provides a quantitative framework for understanding the dynamics of conscious access. It integrates three core components—State Variables, Dynamics and Empirically Constrained Parameters—to capture the interplay between surprise accumulation, threshold adaptation and the probability of conscious ignition.

State Variables
The model employs three central state variables to represent the system’s real-time state:

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
The model’s behavior is fine-tuned by parameters that define its characteristic time scales and sensitivities:
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
        case .apgiMapping:
            return """
APGI Explicit Mapping
Mathematical Variable | Proposed Neural Correlate & Biological Implementation
Surprise (Sₜ) | Population firing rate of "evidence accumulator" neurons. Primary Location: Supragranular layers (2/3) of the Posterior Parietal Cortex (PPC) and Intraparietal Sulcus (IPS). These regions show ramping activity proportional to accumulated evidence. Biological Implementation of dSₜ/dt: Ramping arises from recurrent excitation within local L2/3 microcircuits (pyramidal cells) balanced by feedback inhibition from somatostatin-positive (SOM+) interneurons. The decay term Sₜ/τ is implemented by spike-frequency adaptation in pyramidal cells (via slow K⁺ currents) and synaptic depression. Input f(Πₑ·εₑ, ...): Precision-weighted prediction error arrives via (1) thalamocortical input to L4/L5 and (2) corticocortical projections from sensory and insular regions.
Ignition Threshold (θₜ) | Effective membrane potential threshold for NMDA-spike generation in L5 pyramidal cell apical dendrites. Biological Implementation of dθₜ/dt: γ(θ₀ – θₜ) (Homeostasis): Set by tonic firing of the Thalamic Reticular Nucleus (TRN) which provides baseline GABAergic inhibition to the matrix thalamus, limiting its drive to L1—functioning as the “gatekeeper.” δ·Bₜ₋₁ (Post-Ignition Refractoriness): Caused by (1) short-term synaptic depression in thalamocortical synapses onto L1/L5; (2) after-hyperpolarization (AHP) in L5 pyramidal cells following a burst; (3) activation of SOM+ interneurons providing delayed feedback inhibition. λ·dSₜ/dt (Urgency): Mediated by phasic bursts of Locus Coeruleus–Norepinephrine (LC-NE). NE, via β-adrenergic receptors, potentiates NMDA currents and hyperpolarizes the TRN, directly and rapidly lowering the effective dendritic threshold.
Ignition Probability (Bₜ) | Probability of a self-sustaining, metastable attractor state in the frontoparietal network. Biological Implementation of σ(α(Sₜ – θₜ)): The “switch” is the NMDA-receptor-mediated calcium spike in the apical tuft of L5 pyramidal cells. – When Sₜ > θₜ, the disinhibited matrix thalamus (pulvinar/MD) delivers sufficient coordinated drive to L1 to trigger a regenerative dendritic calcium spike. – This spike propagates to the soma; if coincident with perisomatic input from basal dendrites, it triggers a burst of output spikes—implementing coincidence detection as the nonlinear sigmoid. – Steepness α is determined by apical NMDA receptor density and the degree of thalamic input synchrony.

Surprise Accumulation
Sₜ = Πₑ·|εₑ| + β·Πᵢ·|εᵢ|
Where:
Sₜ: Total precision-weighted surprise at time t
Πₑ: Exteroceptive precision (reliability of external sensory signals)
|εₑ|: Magnitude of exteroceptive prediction error
Πᵢ: Interoceptive precision (reliability of bodily signals)
|εᵢ|: Magnitude of interoceptive prediction error
β: Somatic bias factor (β ≈ 1.2-1.5 baseline, context-modulated)

Ignition Probability
Bₜ = σ(α(Sₜ - θₜ))
Where:
Bₜ: Probability of ignition at time t (0 to 1)
σ: Sigmoid function σ(x) = 1 / (1 + e^(-x))
α: Slope parameter determining steepness of transition
θₜ: Dynamic ignition threshold at time t

Ignition Decision Rule
Ignition occurs when Sₜ > θₜ

Temporal Dynamics of Surprise
dSₜ/dt = −Sₜ/τ + f(Πₑ·εₑ(t), Πᵢ·εᵢ(t)) + σ·η(t)
Where:
τ: Time constant for surprise decay (τ ≈ 200 ms)
f(·): Integration function combining exteroceptive and interoceptive contributions
σ·η(t): Gaussian white noise with standard deviation σ and with unit variance and σ ≈ 0.1·θ₀ captures intrinsic neural variability.
"""
        case .parameterIdentifiability:
            return """
Parameter Identifiability and the Reduced Model
Parameter Recovery and Recoverability Tiers
Reduced, Structurally Identifiable Model

* Sₜ (precision-weighted surprise signal)

* θₜ (baseline ignition threshold)

* Πₑ⁰ (baseline exteroceptive precision)

* β·Πᵢ⁰ (baseline weighted interoceptive precision as a product term)

* α (sigmoid steepness)

* τ (surprise decay constant, fixed at 200 ms based on empirical literature)

* γ (homeostatic recovery rate)

* δ (post-ignition elevation magnitude)

* σ (noise amplitude)
"""
        case .biologicalImplementation:
            return """
Biological Implementation: Explicit Neural Mapping
Variable | Neural Correlate & Mechanism
Sₜ | Ramping activity in PPC/IPS L2/3; recurrent excitation + SOM+ feedback
θₜ | NMDA-spike threshold in L5 apical dendrites; modulated by TRN (homeostasis), AHP/synaptic depression (refractoriness), LC-NE (urgency)
Bₜ | Metastable frontoparietal attractor; NMDA Ca²⁺ spike as sigmoid switch; α set by NMDA density + thalamic synchrony
Πₑ, Πᵢ | ACh ↑ Πₑ; NE ↑ Πᵢ; DA modulates reward salience
β | Insula-ACC connectivity strength; tuned by orexin for arousal state

Neuromodulator | APGI Parameter | LNN Mechanism | Receptor | Effect on τᵢ | Effect on θₜ | Effect on β | Conscious Experience | Clinical Example
ACh | ↑ Πₑ | Shorten τᵢᵉˣᵗᵉʳᵒ | M1 (Gq) | 200→100ms (extero) | —— | —— | Sensory clarity | AD: ↓ACh → cognitive fog
NE | ↓ θₜ, ↑ Πᵢ | Lower readout threshold; shorten τᵢⁱⁿᵗᵉʳᵒ | β, α1 | 150→60ms (intero) | 0.7→0.5 | — | Urgency, threat | Panic: ↑NE → overwhelming alarm
DA | Modulate β (reward) | Amplify reward channel gain; adjust β | D1, D2 | 200→80ms (reward) | — | 1.3→0.9 (pursuit) | Motivation, salience | Addiction: DA surge → cue dominance
5-HT | Stabilize θₜ, Π | Increase γ (homeostasis); narrow Π variance | 5-HT1A, 2A | Stabilize across channels | Stabilize at 0.7 | — | Emotional stability | OCD: ↓5-HT → rigid Π hierarchy
Histamine (TMN) | Set baseline θ₀ | Global excitability scaling | H1, H2 | Global: τᵢ/2 (awake) | θ₀: 0.95→0.70 | — | Wakefulness capacity | Narcolepsy: ↓histamine → θ₀=0.85
Orexin | Coordinate β, others | Context-dependent β; meta-modulation | OX1R, OX2R | Via coordinating others | Via coordinating NE, histamine | 1.3→0.8 (hunger) 1.3→1.7 (satiety) | Energy-state awareness | Narcolepsy-1: No orexin → β uncoordinated
"""
        case .neuromodulatorEffects:
            return """
Neuromodulator Effects on APGI Model State Variables
Neuromodulators act as slow control inputs that reconfigure the APGI system’s operational regime by modulating precision weights (Πₑ, Πᵢ) and the ignition threshold (θₜ). Their effects are receptor-specific, circuit-selective and temporally multiplexed (tonic vs. phasic). Crucially, they do not act in isolation but interact dynamically such as NE and ACh jointly shape signal-to-noise during threat while DA and 5-HT balance exploration vs. stability.

Norepinephrine [NE]
Norepinephrine prepares the system for rapid, critical action by amplifying the urgency of relevant signals. Its effects are not uniform but instead reflect the locus coeruleus (LC)’s topographic projection architecture, producing distinct functional outcomes depending on innervation density—high in regions like the anterior insula (AI) and anterior cingulate cortex (ACC), but low in areas such as the primary visual cortex (V1).
Baseline Threshold (θ₀) and Urgency Gating
Norepinephrine lowers the baseline threshold (θ₀) with a coupling constant (κ_NE) of approximately 0.25–0.35. Phasic LC bursts activate α₁/β-receptors on pyramidal neurons in the AI and ACC, increasing cortical excitability and suppressing the thalamic reticular nucleus (TRN). This reduces the effective threshold (θₜ), thereby lowering the evidence required for ignition during threat or surprise—such as predator detection. The result is rapid access to the cognitive workspace for survival-relevant content.
Interoceptive Precision (Πᵢ) and Soma-Bias Amplification
Norepinephrine boosts interoceptive precision through dense LC projections to the AI and ACC where β-receptors on insular pyramidal neurons enhance the gain for bodily prediction errors. This soma-bias amplification prioritizes internal signals—such as heart rate or pain—over external stimuli during arousal. It explains why sensations like pain or dyspnea dominate conscious awareness under stress.
Somatic Bias (β) and Contextual Reprioritization
Under threat, norepinephrine dynamically increases somatic bias (β), with values rising to 2–5. This gain is topographically biased toward interoceptive hubs (AI/ACC) rather than sensory cortices. As a result, even mild interoceptive deviations exceed the threshold (θₜ) while exteroceptive inputs are filtered unless directly relevant to survival.

Acetylcholine [ACh]
Acetylcholine (ACh) modulates learning by signaling expected uncertainty—indicating that the environment is changing but remains learnable. This role is distinct from norepinephrine (NE) which signals unexpected uncertainty or threat.
Exteroceptive precision (Πₑ)
ACh enhances exteroceptive precision (Πₑ) through projections from the basal forebrain (BF) to the sensory cortex. These projections activate M1 muscarinic and nicotinic acetylcholine receptors (nAChRs), increasing pyramidal neuron excitability and disinhibiting PV+ interneurons. ACh differentially modulates interneuron subtypes, with net effect of sharpening cortical tuning and improving signal-to-noise ratio through coordinated action on pyramidal cells and interneurons. The result is an improved signal-to-noise ratio, sharpening sensory processing. This sensory sharpening heightens the reliability of external prediction errors, particularly in volatile yet learnable contexts, such as navigating a new city.
Baseline threshold (θ₀)
The baseline threshold (θ₀) is modestly lowered (κ_ACh ≈ 0.10–0.20) as M1-mediated depolarization reduces the spike threshold in layer 5 neurons. This adjustment optimizes learning by selectively facilitating plasticity, enabling rapid model updates. Importantly, the threshold is lowered just enough to allow only novel, informative stimuli into the cognitive workspace—specifically those encountered in volatile contexts, rather than all stimuli indiscriminately.
Surprise accumulation (f(·))
ACh influences surprise accumulation (f(·)) by enhancing divisive normalization. It sharpens neural tuning curves, improving competition among neural coalitions. This mechanism ensures that only the most informative external surprises ignite, thereby preventing cognitive overload and supporting selective attention.

Serotonin [5-HT]
Serotonin (5-HT) modulates cognitive processes through distinct, receptor-dependent mechanisms that target specific aspects of neural function and hierarchical information processing. A critical nuance is that serotonin’s effects are both state- and receptor-dependent. Rather than acting as a simple inhibitory neurotransmitter, it modulates the precision hierarchy within neural networks, not merely overall excitability.
Baseline Threshold (θ₀)
At baseline, serotonin elevates the threshold (θ₀) for neural ignition (κ_5HT ≈ 0.35–0.50). By activating 5-HT₁ₐ receptors, it increases potassium (K⁺) conductance, hyperpolarizing pyramidal neurons—particularly in layer 5. This raises the input required for ignition, enforcing stability by suppressing spurious activations in safe or predictable contexts, such as routine tasks. As a result, it reduces false alarms associated with anxiety.
Hierarchical Precision
Serotonin’s influence on hierarchical precision varies by receptor type. Activation of 5-HT₂ₐ receptors diminishes confidence in top-down priors, allowing low-level sensory content to drive ignition—a mechanism observed with psychedelics. In contrast, 5-HT₁ₐ receptors enhance confidence in high-level priors, effectively suppressing perceptual noise. This dual role—stabilizing beliefs via 5-HT₁ₐ and relaxing them via 5-HT₂ₐ—aligns with the REBUS (Relaxed Beliefs Under Psychedelics) model. It explains why selective serotonin reuptake inhibitors (SSRIs) alleviate anxiety while psychedelics induce ego dissolution.
Post-Ignition Refractoriness (δ)
Following ignition, serotonin potentiates post-ignition refractoriness (δ) by enhancing inhibition which prolongs the recovery period. This cognitive filtering prevents rapid re-ignition, supporting sustained focus and attentional control.

Dopamine [DA]
Dopamine (DA) functions as a value signal for adaptive resource allocation, dynamically adjusting cognitive and motivational processes through distinct tonic and phasic mechanisms. This involves ventral striatum outputs modulating ACC activity which in turn influences LC-NE release, creating a polysynaptic loop that integrates value with bodily state. A critical nuance lies in dopamine’s bidirectional effects: tonic activity raises θₜ to stabilize the system while phasic activity selectively lowers the effective threshold for salient content. This duality clarifies the paradox observed in schizophrenia where hallucinations (over-ignition of irrelevant noise) coexist with avolition (under-ignition of meaningful goals). Through these mechanisms, dopamine shapes how the brain prioritizes and responds to meaningful stimuli.
Baseline threshold (θ₀)
In safe or stable contexts, the baseline threshold (θ₀) increases, with tonic dopamine activating D2 receptors on cortical interneurons. This enhances inhibition of layer 5 basal dendrites, raising the threshold (θₜ) and promoting resource conservation. By suppressing the activation of non-goal-relevant content—such as filtering out distractions during a meal—this mechanism helps maintain focus in rewarding or stable environments.
Precision for Salient Errors
For precision in detecting salient errors, dopamine operates phasically. Phasic dopamine bursts activate D1 receptors, amplifying NMDA currents in the prefrontal cortex (PFC) and striatum. This heightens the gain for reward-prediction errors, ensuring that unexpected rewards or their omissions receive elevated salience (Π). As a result, these events trigger updates to value models, refining the brain’s predictive accuracy.
Somatic bias (β)
Dopamine indirectly influences somatic bias (β) by acting on the ventral striatum which modulates the anterior cingulate cortex (ACC) and norepinephrine (NE) release. This interaction bridges homeostatic needs—such as hunger or thirst—with incentive salience, elevating the salience (Πᵢ) of motivationally relevant stimuli.
"""
        case .neuromodulatoryImplementation:
            return """
Neuromodulatory Implementation of APGI Control Parameters
Neuromodulator | Primary Source | Key Receptors | Effect on Πₑ | Effect on Πᵢ | Effect on θₜ | Key Computational Role
Norepinephrine (NE) | Locus Coeruleus | α₁/β (Cortex) | Minor Increase | Major Increase | Lowers (Phasic) | Urgency, Soma-Bias, Threat Response
Acetylcholine (ACh) | Basal Forebrain | M1, nAChR | Major Increase | Minor/Contextual | Lowers (Modest) | Expected Uncertainty, Sensory Learning
Serotonin (5-HT) | Raphe Nuclei | 5-HT₁ₐ | Decreases | Decreases | Raises (Tonic) | Stabilizes Priors, Enforces Stability
5-HT | Raphe Nuclei | 5-HT₂ₐ | Increases | Increases | Lowers | Relaxes Priors, Promotes Plasticity
Dopamine (DA) | VTA/SNc | D1 (PFC) | Increases (Salient) | Increases (Salient) | Lowers (Phasic) | Signals Salience, Reward PE
Dopamine (DA) | VTA/SNc | D2 (Interneurons) | - | - | Raises (Tonic) | Resource Conservation, Focus
"""
        case .explicitNeuromodulator:
            return """
Explicit Neuromodulator Mapping
Concept | Definition | Primary Location | Biological Implementation | Inputs
Surprise (Sₜ) | Population firing rate of "evidence accumulator" neurons. | Supragranular layers (2/3) of the Posterior Parietal Cortex (PPC) and Intraparietal Sulcus (IPS). | Ramping activity from recurrent excitation in local L2/3 microcircuits (pyramidal cells) balanced by feedback inhibition from SOM+ interneurons. Decay term (-Sₜ/τ) implemented by spike-frequency adaptation in pyramidal cells (slow K⁺ currents) and synaptic depression. | Precision-weighted prediction error via (1) thalamocortical input to L4/L5 and (2) corticocortical projections from sensory and insular regions.
Ignition Threshold (θₜ) | Effective membrane potential threshold for NMDA-spike generation in L5 pyramidal cell apical dendrites. | Not explicitly stated as a primary location, but mechanisms involve Thalamic Reticular Nucleus (TRN), matrix thalamus, L1 and L5 pyramidal cells. | Homeostasis (-γ(θ₀ – θₜ)): Set by tonic firing of TRN, providing baseline GABAergic inhibition to the matrix thalamus, limiting its drive to L1. Post-Ignition Refractoriness (δ·Bₜ₋₁) : Caused by (1) short-term synaptic depression in thalamocortical synapses onto L1/L5; (2) after-hyperpolarization (AHP) in L5 pyramidal cells; (3) activation of SOM+ interneurons. Urgency (-λ·dSₜ/dt): Mediated by phasic bursts of Locus Coeruleus–Norepinephrine (LC-NE). NE potentiates NMDA currents and hyperpolarizes the TRN. | Not explicitly stated as direct inputs for the threshold itself, but rather factors influencing its change.
Ignition Probability (Bₜ) | Probability of a self-sustaining, metastable attractor state in the frontoparietal network. | Apical tuft of L5 pyramidal cells (for the "switch"). | The "switch" is the NMDA-receptor-mediated calcium spike in the apical tuft of L5 pyramidal cells. When Sₜ > θₜ, the disinhibited matrix thalamus delivers sufficient coordinated drive to L1 to trigger a regenerative dendritic calcium spike. This spike propagates to the soma and, if coincident with perisomatic input, triggers a burst of output spikes (coincidence detection). Steepness α is determined by apical NMDA receptor density and thalamic input synchrony. | Disinhibited matrix thalamus (pulvinar/MD) providing coordinated drive to L1; perisomatic input from basal dendrites.
"""
        case .mappingCognitiveToApgi:
            return """
Mapping Cognitive Constructs→ APGI 
Control Parameters encompass neuromodulator-regulated factors, including the ignition threshold (θ₀), exteroceptive precision (Πₑ), interoceptive precision (Πᵢ) and urgency (gain modulation). These parameters set the foundational conditions for cognitive processing. Neural Representations involve latent hypotheses—whether perceptual, interoceptive or mnemonic—that compete for global ignition and are driven by precision-weighted prediction error minimization, a process that determines which hypotheses gain prominence in conscious experience. Output Behaviors refer to the observable outcomes of integrated conscious content, manifesting as decisions, reports or actions and reflect the culmination of the cognitive processes.

Cognitive Constructs → APGI Parameters
COGNITIVE CONSTRUCT | APGI CONSTRUCT | ONTOLOGICAL LEVEL | MECHANISTIC INTERPRETATION & NEUROMODULATORY BASIS
Attention | Salience-triggered ignition | Output Behavior | Result of anterior insula–ACC detecting high-precision prediction errors (Π·δ); ignition gates access to frontoparietal global workspace.
Salience | Precision-weighted prediction error (Π·δ) | Neural Representation | Magnitude of Π·δ; encoded in salience network (AI/ACC); determines competitive eligibility for ignition.
Cognitive Load | θ₀ modulation (Ignition Threshold) | Control Parameter | Elevated load → increased θ₀ (e.g., via reduced tonic DA or elevated adenosine); reflects resource depletion in frontoparietal circuits.
Bias Sensitivity | Prior strength in predictive coding | Neural Representation | Reflects over-weighted high-level priors (e.g., via 5-HT1A receptors); resists updating even with high Π·δ.
Sensory Precision (Πₑ) | Πₑ | Control Parameter | Direct APGI parameter; set by ACh via nicotinic/muscarinic receptors in sensory cortices (layers 2/3).
Predictive Coding Efficiency | Prediction error minimization fidelity | Neural Representation | Overall fidelity of hierarchical inference; depends on optimal Πᵢ allocation and recurrent circuit integrity (thalamocortical loops).
Prediction Error Minimization | Core inference objective | Neural Representation | The computational goal of the system; drives representation competition and updates.
Learning Rate | Πᵢ-modulated plasticity | Control Parameter | Scales with Πₑ (ACh) and Πᵢ (NE); determines how strongly δ updates priors (NMDA/cAMP-dependent plasticity).
Feedback Integration | Integration-phase updating | Output Behavior | Post-ignition incorporation of outcome into memory; mediated by phasic DA (PE) and NE (β-receptor plasticity).
Expectancy | Top-down prior | Neural Representation | High-level prediction; stabilized by 5-HT1A and suppressed during 5-HT2A activation (REBUS/psychedelics).
Flexibility | θ₀ and Πᵢ adaptability | Control Parameter | Reflects dynamic range of θ₀ (DA/NE) and Πᵢ (ACh/NE); low in rigid states (e.g., high 5-HT1A tone).
Uncertainty Tolerance | Inverse of Πᵢ (Pi^{-1}) | Control Parameter | Low Πᵢ (high uncertainty) → reduced gain on prediction errors; mediated by low ACh/NE tone.
Certainty | High Πᵢ | Control Parameter | High precision → strong weighting of sensory evidence (Πₑ) or interoceptive signals ( Πᵢ); implemented by ACh or NE.
Error Detection | Mismatch signal (δ) | Neural Representation | Generated in prediction error units (e.g., superficial cortical layers); amplified if Π·δ exceeds local threshold (θ₀).
Memory Encoding/Retrieval | Integration-phase binding | Output Behavior | Conscious content (post-ignition) is encoded via hippocampal–prefrontal theta–gamma coupling; modulated by NE and ACh.
Motivational Energy | Tonic DA level | Control Parameter | Reflects baseline expected value; sets global θ₀ expectations via D2-mediated inhibition (high DA → lower task θ₀).
Agency | Post-ignition attribution | Output Behavior | Emerges from integration where motor intentions generate sensory feedback that matches predictions; requires intact ignition-to-action coupling in SMA-parietal circuits; disrupted if ignition fails to propagate.
Self-Efficacy | Trait-like prior on capability | Neural Representation | A high-level prior ("I can succeed") that modulates θ₀ expectations for goal-directed action.
Reward Sensitivity | Phasic DA response | Neural Representation | Encodes δ for reward; triggers D1-mediated NMDA enhancement → lowers θ₀ for reward-linked representations.
Temporal Discounting | Time-sensitive value prior | Neural Representation | Reflects decay in expected value over delay; encoded in orbitofrontal–striatal circuits; modulated by DA tone.
Energy Conservation | High θ₀ baseline | Control Parameter | Favors Autopilot Mode (Unconscious Control); implemented by elevated adenosine, 5-HT1A tone or low NE/DA.
Flow State | Optimal θ₀- Π balance | Emergent State (optimal θ₀-Π balance) | Low θ₀ (high NE/DA) + high task-relevant Π → seamless ignition; minimal distraction (low Πᵢ for irrelevant inputs).
Emotional Valence | Affective prediction error | Neural Representation | Computed in amygdala–insula; weighted by Πᵢ (NE); tags content as approach/avoid.
Somatic Markers | Interoceptive priors | Neural Representation | Bodily state predictions ("this feels risky") stored in insula; influence decisions via Πᵢ-weighted ignition.
Interoceptive Awareness | Πᵢ | Control Parameter | Direct APGI parameter; set by NE via α1/β receptors in anterior insula, ACC and orbitofrontal cortex.
Resilience | Stable high-level priors | Neural Representation | Reflects resistance to Πᵢ-driven perturbations (e.g., stress); supported by 5-HT1A tone reinforcing default predictions.
Cognitive Dissonance | Prediction error from value conflict | Neural Representation | Arises when action-generated interoceptive outcomes violate high-precision value priors; creates large δ in ACC and Πᵢ·|εᵢ| that may trigger repeated ignition until resolution.
Trust | Social prior strength | Neural Representation | High-level social prediction ("others are reliable"); modulated by oxytocin but evaluated via Πᵢ-weighted social prediction errors.
Empathy | Simulated interoceptive state | Neural Representation | Involves ignition of vicarious bodily states; requires high Πᵢ for others’ signals (insula–ACC resonance).
Social Affiliation | Social value prior | Neural Representation | Motivational prior encoded in septal–VTA circuits; modulates θ₀ for social stimuli via DA.
Contextual Awareness | Hierarchical prior integration | Neural Representation | Ability to anchor percepts in situational model; requires intact DMN–Salience network coupling during integration.
Identity Alignment | Core self-model prior | Neural Representation | Stable high-level prior in medial prefrontal cortex; resists updating unless Πᵢ/Πe · δ is very high (e.g., crisis).
Curiosity | Precision-seeking drive | Control Parameter | Reflects expected information gain; may lower θ₀ for novel stimuli via DA (exploration bonus).
Predictive Imagination | Counterfactual simulation | Neural Representation | Requires ignition of internally generated scenarios (hippocampal–prefrontal); gated by θ₀ and Πᵢ for internal models.
Narrative Coherence | Integration-phase binding | Output Behavior | Post-ignition synthesis of events into story; depends on DMN integrity and working memory function.
Purpose Centrality | Superordinate value prior | Neural Representation | Highest-level prior ("my life has meaning"); shapes θ₀ expectations for all goal-relevant content.
"""
        case .apgiToCognitive:
            return """
APGI Parameters → Cognitive Constructs
Parameter | Associated Cognitive Constructs | Mechanics
θ₀ (Baseline Ignition Threshold) | Cognitive Load Capacity, Energy Conservation Mode, Distractibility (inverse), Concentration Capacity, Motivational Readiness, Flexibility, Certainty Tolerance, Rumination Resistance, Mind-Wandering Propensity (inverse) | Sets the "hurdle height" for conscious access; modulated by adenosine (fatigue), orexin (arousal), tonic DA (expected value) and 5-HT₁ₐ (stability)
Πₑ (Exteroceptive Precision) | Sensory Awareness, External Attention Gain, Perceptual Learning Rate, Environmental Error Detection, Perceptual Discrimination, Sensory Overload Vulnerability, Predictive Coding Efficiency (external domain) | Controlled primarily by ACh (nicotinic/muscarinic); reflects confidence in external sensory signals
Πᵢ (Interoceptive Precision) | Interoceptive Awareness, Emotional Intensity, Somatic Marker Strength, Empathy (affective component), Body-Mind Connection, Stress Resilience (context-dependent), Gut Feelings, Affective Bias Sensitivity | Controlled primarily by NE (α₁/β receptors); reflects confidence in bodily signals; anatomically biased toward insula-ACC
β (Soma-Bias Factor) | Body-Prioritization, Introversion-Extroversion (partial), Private Self-Consciousness, Somatization Tendency, Internal vs External Locus, Stress Response Style | Estimated ~1.2-1.5 baseline; reflects evolutionary/architectural prioritization of interoceptive signals
Sₜ (Surprise Accumulation) | Novelty Detection, Salience, Alertness, Orienting Response, Unexpectedness Sensitivity | Real-time integration of Π-weighted prediction errors; determines proximity to threshold
dSₜ/dt (Rate of Surprise Change) | Urgency Perception, Time Pressure Sensitivity, Threat Imminence, Flow State Dynamics, Looming Stimulus Detection | Drives λ-mediated threshold lowering; explains "faster-than-expected" conscious access under threat
"""
        case .ignitionTimeline:
            return """
Ignition Timeline (0–500 ms)
Ignition unfolds as a stereotyped, temporally precise cascade across thalamocortical microcircuits. Below is a canonical timeline anchored to stimulus onset (t = 0 ms), with neural events resolved in 50-ms bins. This sequence integrates laminar electrophysiology, circuit anatomy and computational function.

Time (ms) | Thalamocortical/Cortical Interactions | Event/Network Activity | Functional Interpretation
0–50 | Matrix thalamus (pulvinar/MD) projects synchronously to cortical layer 1. Apical dendrites of frontoparietal L5 pyramidal neurons receive strong depolarizing drive. | Pulvinar/MD → L1 apical tufts (dlPFC, PPC, AI) | Trigger: Neuromodulatory gain (e.g., NE-mediated) disinhibits thalamus, initiating apical integration, the circuit translation of precision-weighting enabling ignition.
50–100 | NMDA-receptor-mediated Ca²⁺ spikes erupt in L5 apical dendrites. Somatic bursting begins if coincident with basal dendritic input. PV⁺ interneurons provide transient feedforward inhibition which is overcome by shunting and divisive normalization. | L5 pyramidal neurons (dlPFC, PPC); PV⁺ interneurons | Amplification: Dendritic spikes amplify precision-weighted prediction errors; winner-take-all competition intensifies.
100–150 | Burst output from L5 propagates to L2/3. Recurrent excitation initiates within frontoparietal microcolumns. Gamma-band (30–80 Hz) power begins to rise locally. | L2/3 pyramidal neurons; local recurrent loops | Local Stabilization: Horizontal integration begins; coalition-specific gamma synchrony emerges.
150–200 | Long-range gamma phase-locking initiates between frontal, parietal and insular regions. P3a ERP peaks (~200 ms), reflecting salience detection and frontoinsular engagement. | AI–ACC–dlPFC network; frontoparietal synchrony | Salience Broadcast: Interoceptive/exteroceptive relevance is signaled to executive systems.
200–250 | Sustained high-firing attractor state consolidates. TRN re-engagement begins via SOM⁺ feedback, setting up future refractoriness. Pupillary dilation peaks (LC-NE burst). | Thalamocortical loops; LC–NE system | Metastability: The Sₜ > θₜ condition is met. The network enters a self-sustaining regime; neuromodulatory urgency signal peaks.
250–300 | P3b ERP peaks (~300 ms) over parietal scalp. Peak gamma synchrony between frontoparietal and temporal regions. PCI rises above 0.4 if perturbed. | PPC (P3b generator); frontotemporal gamma | Ignition Confirmation: Global availability achieved; content is reportable and memory-encodable.
300–350 | Hippocampal sharp-wave ripples begin to encode ignited content. Language areas activate if verbal report is required. | Hippocampus, left perisylvian cortex | Memory & Report: Episodic encoding and linguistic formulation commence.
350–400 | Threshold θₜ begins to rise due to δ·Bₜ₋₁ term (post-ignition refractoriness). SOM⁺ interneurons enforce feedback inhibition. | L5–SOM⁺ microcircuit; thalamocortical synapses | Refractory Initiation: System prepares for attentional blink and prevents simultaneous conscious contents. Active inhibition raises θₜ (formalized as δ·Bₜ₋₁), implementing post-ignition suppression.
400–450 | Frontoparietal firing remains elevated but begins to decay if not actively maintained. Alpha oscillations rebound, reinstating inhibitory tone. | dlPFC, PPC; thalamocortical alpha generators | Stabilization or Decay: Content remains globally available only if rehearsed such as in working memory.
450–500 | Activity returns toward baseline in non-maintained trials. Theta-phase binding may group this ignition into a 3-second “specious present” window. | Hippocampal–DMN theta; residual gamma | Temporal Integration: Ignition event is bound into ongoing conscious narrative stream.

This timeline is testable with intracranial EEG, laminar probes and concurrent pupillometry. Deviations (e.g., delayed P3b, absent L5 spiking) predict failed ignition or altered states (e.g., anesthesia, schizophrenia). The sequence reflects the transition from local surprise accumulation to global, self-sustaining attractor dynamics.
"""
        case .neuromodulatoryControl:
            return """
Neuromodulatory Control System
Neuromodulator | Primary APGI Parameter | Mechanism | Effect
ACh | ↑ Πₑ | M1 receptors ↑ signal-to-noise | Sharper sensory detail
NE | ↓ θₜ, ↑ Πᵢ | β-receptors ↑ NMDA, ↓ TRN | Urgency gating
DA | Modulates β (reward) | D1 receptors in PFC/striatum | Biases toward reward
5-HT | Stabilizes θₜ | 5-HT1A/2A balance | Prevents erratic ignition
Orexin | Modulates β (arousal) | Coordinates LC/BF/TMN | Tunes bias by state
"""
        case .psychiatricDisorders:
            return """
APGI for Psychiatric Disorders with Specific Precision Profiles
Disorder-Specific Precision Profiles
Disorder | APGI Dysregulation | Mechanism | Treatment Implication
Panic | ↑ Πᵢ, ↓ θₜ | Somatic priors → catastrophe | Interoceptive exposure; β-blockers
MDD | ↓ Πᵢ, ↑ θₜ | Blunted interoception; high threshold | Behavioral activation; DA modulation
Schizophrenia (+) | Aberrant Π | DA tags noise as salient | D₂ antagonists; metacognitive training
GAD | ↑ Πₑ (threat) | High-confidence threat priors | CBT; SSRIs (↑ θₜ)
PTSD | ↑ Πᵢ (trauma) | Hyper-precise somatic markers | EMDR; MDMA (↓ Πᵢ)
ASD | Inflexible Π | High Πₑ (detail), low Πₑ (social) | Sensory integration training
ADHD | Unstable Πₑ | NE dysregulation → fluctuating gain | Stimulants (stabilize NE)

Anxiety Disorders: Heterogeneous Precision Dysregulations
Disorder | Precision Profile | Mechanism | Neural Signatures | Treatment Implications
Generalized Anxiety Disorder (GAD) | • Elevated Πₑ for threat-related stimuli• Hyperactive prefrontal threat priors• Mild somatic involvement | Prefrontal cortex generates high-confidence catastrophic predictions; ambiguous stimuli confirm priors. | • Hyperactive P3b to cognitive-semantic threat words• Elevated frontal alpha asymmetry• Hyperconnectivity: dlPFC-amygdala | • CBT: Recalibrates threat priors• SSRIs: Stabilizes priors, elevates θₜ• Mindfulness: Weakens prior confidence
Panic Disorder | •Pathologically elevated Πᵢ for interoceptive signals• Maladaptive somatic priors (M_{c,a}) | Somatic markers predict catastrophe; positive feedback loop amplifies Πᵢ. | • Exaggerated P3b to bodily perturbations• Hyperconnectivity: insula-amygdala-LC• Heightened heartbeat-evoked potentials | •Interoceptive exposure: Updates M_{c,a} to predict safety• β-blockers: Break feedback loop• SSRIs: Reduce interoceptive gain
Social Anxiety Disorder | •Context-specific elevation of Πᵢ and Πₑ during social evaluation• Hypervigilance to social cues | Social contexts activate M_{social_threat}; high Πₑ for facial expressions, Πᵢ for visible symptoms. | •Context-dependent AI-LC hyperconnectivity• Enhanced P3b to social-evaluative faces• Amygdala hyperreactivity | •Exposure therapy: Updates M_{social_threat}• CBT: Reduces precision for negative interpretations• β-blockers: Reduce visible symptoms

Disorders of Consciousness: Thalamocortical Disconnection
State | Mechanism | Neural Signatures | Clinical Application
Coma | Complete thalamocortical disconnection. | Absence: P3b, gamma synchrony, PCI ≈ 0. | PCI (TMS-EEG) as diagnostic classifier.
Vegetative State | Partial thalamocortical activity; no global broadcast. | Early ERPs present; no P3b, PCI < 0.3. | P3b in auditory oddball suggests ignition capacity.
Minimally Conscious State | Fluctuating thalamocortical connectivity. | Intermittent P3b, variable gamma, PCI 0.3–0.5. | Frontoparietal connectivity predicts consciousness.

Disorder | Primary APGI Dysregulation | Consequence for Conscious Experience
GAD/Social Anxiety | ↑ Πᵢ (High Interoceptive Precision) | Constant conscious worry; bodily false alarms
Panic Disorder | ↑ Πᵢ & ↓ θₜ (Acute Collapse) | Overwhelming, sudden conscious panic
MDD | ↓ Πᵢ & ↑ θₜ (Low Precision, High Threshold) | Anhedonia, emotional numbing, lack of motivation
Bipolar I (Manic) | ↓ θₜ (Collapsed Threshold) | Racing thoughts, sensory flooding, distractibility
OCD | ↑ Precision on Maladaptive Priors | Conscious domination by obsessions; rigid compulsions
Schizophrenia | Global Precision Dysregulation | Hallucinations (internal priors dominate), Delusions
BPD | Labile Πᵢ & θₜ | Intense, unstable emotional consciousness
ASPD | ↓ Πᵢ for Empathy/Fear | Lack of conscious guilt or empathy
Gender Dysphoria | Mismatched Body Model vs. Interoception | Conscious feeling that body is "wrong"
ADHD | Unstable Πₑ | Distractibility; conscious focus flickers
Autism (ASD) | Inflexible Hierarchy; High Πₑ | Sensory overload; difficulty with social priors
Anorexia Nervosa | Distorted Body Model; ↓ Πᵢ for Hunger | Body image distortion; hunger ignored
PTSD | Hyper-precise Traumatic Somatic Markers | Intrusive, vivid flashbacks and hypervigilance
Insomnia | Failure to Raise θₜ for Sleep | Conscious awareness when unconsciousness is needed
Addiction | Substance-Induced θₜ/Π Manipulation | Consciousness dominated by craving and drug-seeking
"""
        case .thermodynamicEfficiency:
            return """
Thermodynamic and Evolutionary Efficiency
Physical Constraint | APGI Solution | Efficiency Argument | Alternative Solutions
Finite ATP budget (~10⁹ ATP/spike) | Sparse, event-driven processing via threshold (θₜ) | Only fire when prediction error exceeds threshold; saves 60-80% energy vs. continuous firing | Dense coding with lower per-spike cost? Analog computation?
Slow transmission (50-100ms delays) | Predictive processing via hierarchy | Compensate for delays by predicting future states | Reactive processing with faster signals (e.g., gap junctions, larger axons)?
Stochastic neurons (~50% synaptic reliability) | Bayesian population coding with precision-weighting (Π) | Integrate over populations, weight by confidence | Error correction codes? Redundancy without weighting?
Embodied system (survival-critical) | Interoceptive prioritization (β > 1) | Ensure body-state signals trigger fast responses | External threat prioritization? Balanced weighting?
Slow, unreliable components | Hierarchical temporal integration | Leverage multiple timescales for stability | Flat architectures with fast components?
"""
        case .epistemicStandards:
            return """
Epistemic Standards
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
 case .bibliography:
            return "Key references: "
        case .glossary:
            return "APGI: Awareness-Precision-Gain-Ignition model; θ: Ignition threshold; β: Modulation coefficient; GNWT: Global Neuronal Workspace Theory; dlPFC: Dorsolateral prefrontal cortex."
        case .targetAudience:
            return "Profile: Neuroscientists, philosophers of mind, psychologists (PhD level); Educated generalists interested in consciousness; Policymakers for AI ethics. Assumes familiarity with basic neuroscience; provides metaphors for accessibility."
        }
    }
}
