import Combine
import SwiftUI

struct ApgiToPsyStateView: View {
    private let mappingBody = """

    APGI parameter table for psychological states

    APGI parameters

    Prediction Error (ε) → Magnitude of dominant prediction mismatch, " +
                    "expressed in normalized standard deviation units (σ) " +
                    "relative to the individual baseline

    Precision (π) → Channel-specific precision weighting; " +
                    "the relative gain applied to prediction errors in particular domains " +
                    "(e.g., threat, social, interoceptive), reflecting inverse variance (confidence)

    Threshold (θₜ) → Dynamic ignition barrier; " +
                    "expressed as percentage deviation from an individual's baseline ignition threshold " +
                    "(baseline = 0%). Negative values: lowered threshold (easier ignition). " +
                    "Positive values: elevated threshold (harder ignition)

    Threshold (θₜ) → Dynamic ignition barrier; " +
                    "expressed as percentage deviation from an individual's baseline ignition threshold " +
                    "(baseline = 0%). Negative values: lowered threshold (easier ignition). " +
                    "Positive values: elevated threshold (harder ignition)

    Somatic Bias (β) → Ratio of interoceptive (inward, bodily/self-referential) " +
                    "to exteroceptive (outward, environmental/social) attentional orientation. " +
                    "β > 1: inward bias, β < 1: outward bias


    State
    Prediction Error (ε)
    Precision (π)
    Threshold (θₜ)
    Somatic Bias (β)
    Key Signature
    Flow state
    Highly accurate (>95%), task-aligned predictions
    Task: +4σ; Distractor: <0.5σ
    Task: -10 to -15% (stable, <5% variance)
     0.9-1.1 (balanced)
    Temporal entrainment, metacognitive suppression

    Joy/Happiness
    Predictions meet/exceed expectations by >20%
    Positive outcomes: +2 to +3σ
    Positive content: -15 to -20%
     1.0-1.3 (mild somatic amplification)
    Ventral striatal activation, sustained positive RPE

    Gratitude
    Social predictions resolved favorably
    Social/attachment: +2 to +4σ; Safety interoception elevated
    Social-affiliative: -10 to -15%
     1.2-1.5 (safety signals amplified)
    Oxytocin-mediated, requires temporal extension

    Hope
    Moderate confidence (60-75%), high expected value despite uncertainty
    Future-oriented: +2 to +3σ
    Outcome-relevant: -12 to -18% (tonic dopamine)
     1.0-1.2
    Sustained tonic DA maintaining accessibility

    Optimism
    Generalized positive priors (>70% positive outcomes)
    Positive: +1.5 to +2σ constitutively
    Confirmatory evidence: -8 to -12%
     0.9-1.1
    Stable positive prior distribution, trait-like

    Awe
    Massive prediction error (>4σ) from vastness/novelty
    Global: +3 to +5σ transiently (2-10s)
    Global: -20 to -30% (brief suppression)
     0.8-1.0 (reduced self-focus)
    DMN suppression, model inadequacy signal

    Inspiration
    Latent pattern detection, remote associations
    Abstract/pattern: +2 to +4σ
    Beyond-task associations: -10 to -15%
     0.9-1.1
    DMN-FPN coupling, coherence > strength weighting

    Serenity
    High accuracy (>90%), low-surprise environment
    Threat: <0.3σ; External vigilance: +15 to +25%
    Internal calm: -10 to -15%
     1.2-1.4 (internal safety signals)
    Dual-threshold architecture, parasympathetic dominant

    Pride
    Self-model prediction confirmed/exceeded
    Self-achievement: +3 to +4σ
    Self-referential: -12 to -18%
     1.5-2.0 (postural/somatic expansion)
    Strong embodied component, somatic confirmation

    Amusement
    Benign violation (1-2σ surprise in safe context)
    Social incongruity: +2 to +3σ; Threat: <0.5σ
    Playful content: -15 to -20%
     1.0-1.2
    Rapid ignition (<200ms), mesolimbic reinforcement

    Love (romantic)
    Long-term attachment predictions, partner-focus
    Attachment-specific: +4 to +6σ; Temporal window +40-60%
    Partner-relevant: -20 to -30%
     1.8-2.5 (visceral states dominate)
    Extreme metabolic cost, oxytocin/vasopressin mediated

    Curiosity
    Information gaps actively detected
    Uncertainty signals: +2 to +4σ (amplified, not minimized)
    Exploratory content: -10 to -18%
     0.9-1.1
    Inverted PE response—uncertainty valued

    Engagement
    Task-aligned, sustained accuracy
    Task: +3 to +4σ; Distractor: <0.8σ
    Task: -10 to -15% (±10-20% variance)
     1.0-1.2
    Effortful control maintained, no metacognitive suppression

    Mindfulness
    Reduced top-down strength (-30-40%), error acceptance
    Equalized (Πₑₓₜ ≈ Πᵢₙₜ ±10%)
    Habitual: +20 to +30%; Present-moment: -15 to -20%
     1.3-1.6 (heightened interoceptive awareness)
    Non-judgmental, dual threshold adjustment

    Neutrality
    Balanced, accurate priors
    All channels: baseline ±0.3σ
    Resting set-point (individual-typical)
     1.0 (baseline)
    Homeostatic equilibrium, rare phenomenologically

    Boredom
    Over-learned, near-zero PE (<0.5σ)
    Global suppression: -2 to -3σ (low expected value)
    Elevated: +20 to +35% (resource conservation)
     0.8-1.0
    Aversive meta-signal motivates exploration

    Daydreaming
    Endogenously generated predictions dominate
    External: <0.4σ; Internal/memory: +2 to +3σ
    Internal: -15 to -25%
     0.8-1.0 (reduced external grounding)
    DMN dominance, spontaneous ignition

    Distraction
    Fragmented, competing accurate predictions
    Multiple competing streams (each +2 to +3σ)
    Crossed repeatedly by different inputs
     1.0-1.2
    Reservoir coherence degraded, rapid switching

    Fatigue
    Slowed PE accumulation, shortened integration window
    Global reduction: -2 to -4σ
    Elevated: +20 to +40% (adenosine/glucose depletion)
     0.9-1.1
    Metabolic constraint protection mechanism

    Anxiety
    Threat-biased expectations
    Threat: +3 to +6σ
    Threat-relevant: -25 to -40%
     1.5-2.5 (interoceptive hypervigilance)
    False alarm generator, self-reinforcing cycle

    Stress
    Persistently violated, non-selective arousal
    Non-selective global elevation: +2 to +4σ
    Unstable: ±15-25% fluctuation
     1.3-1.8 (sympathetic activation)
    NE-mediated saturation, eventual burnout

    Depression
    Pessimistic, rigid negative priors
    Reward: -3 to -5σ; Negative: +2 to +3σ
    Positive: +30 to +50%; Negative: -10 to -20%
     0.7-0.9 (reduced embodiment/anhedonia)
    Computational trap, asymmetric filtering

    Anger
    Goal obstruction, injustice detection
    Injustice/obstruction: +3 to +5σ
    Action-preparation: -20 to -35%
     1.8-2.5 (muscle tension, CV arousal)
    NE surge, rapid behavioral mobilization

    Fear
    Imminent threat, immediate reactive mode
    Threat: +4 to +7σ
    Threat-relevant: -40 to -60%
     2.5-4.0 (somatic signals dominate)
    Amygdala-driven, extreme urgency configuration

    Guilt
    Self-model violation, moral error replay
    Self-monitoring: +3 to +5σ; Internal β elevated
    Self-monitoring: -20 to -30%
     1.8-2.5 (moral wrongness felt)
    Recurrent ignition, self-correction function

    Shame
    Social self-model violated, imagined observers
    Social-threat: +4 to +6σ (imagined evaluation)
    Social-threat: -25 to -40%
     2.0-3.0 (withdrawal posture, blushing)
    Global ignition, self-devaluation, MPF-TPJ network

    Loneliness
    Social predictions unmet, persistent absence
    Social-absence: +2 to +4σ
    Social-threat/rejection: -15 to -25%
     1.2-1.5 (isolation somatic discomfort)
    Paradoxical rejection sensitivity, self-fulfilling

    Frustration
    Repeated goal-blocking, maintained effort
    Goal-relevant: +2 to +4σ (maintained despite failure)
    Oscillating: ±20-30%
     1.2-1.6 (arousal building)
    Unstable threshold, escalation/abandonment negotiation

    Confusion
    Competing models, ambiguous evidence
    Diffused across alternatives (no dominant >3σ)
    Normal, but no signal crosses cleanly
     1.0-1.2
    Model selection failure, high-entropy state

    Disgust
    Contamination/pathogen detection confirmed
    Contamination: +3 to +5σ
    Rejection/avoidance: -20 to -30%
     2.0-3.0 (nausea, gag reflex)
    Anterior insula-driven, visceral dominance

    Envy
    Social comparison mismatch, status threat
    Social-comparison: +2 to +4σ
    Status-relevant: -15 to -25%
     1.1-1.4
    Desire + resentment, self-model threatened

    Jealousy
    Attachment security threatened, rival detected
    Rival-related: +3 to +5σ
    Defensive cognition: -20 to -35%
     1.5-2.0 (somatic anxiety)
    Mate-guarding function, hypervigilance for betrayal

    Regret
    Counterfactual error (past ≠ optimal)
    Self-blame: +3 to +5σ
    Autobiographical memory: -15 to -25%
     1.2-1.5
    Learning signal, recurrent "what if" ignition

    Pessimism
    Negative outcome priors (>60%)
    Positive PE: -2 to -3σ (suppressed)
    Positive content: +20 to +35% (filtered)
     0.9-1.1
    Prior distribution bias, anticipatory not current

    Overwhelm
    Excessive concurrent demands
    Multiple high-Π streams (total >10-15 concurrent)
    Chaotically exceeded, fragmented ignition
     1.5-2.0 (sympathetic feedback)
    Reservoir saturation, computational collapse

    Dissociation
    Prediction-body coupling severed
    Interoceptive: approaches zero
    Embodied content: +40 to +70%
     <0.3 (dramatic suppression)
    Prefrontal-insula uncoupling, protective detachment

    Trance
    Top-down predictions dominate (>3× posterior)
    External: <0.3σ; Endogenous rhythmic: elevated
    Endogenous rhythmic: -20 to -35%
     0.7-1.0 (internal focus)
    Self-sustained ignition, reduced sensory gating

    Hallucination
    Internal predictions misattributed as sensory
    Internal erroneously assigned: +3 to +6σ
    Crossed by purely internal signals
     Variable (depends on type)
    Reality monitoring failure, source confusion

    Déjà Vu
    Temporal misalignment, false familiarity
    Momentary match with decaying trace
    Briefly crossed prematurely
     1.0-1.2
    Temporal-binding error, 2-10s duration

    Hypnagogia
    Sensory-decoupled, fragments blend
    External declining, internal maintained/elevated
    Dream content: -20 to -40%
     0.8-1.2 (variable)
    Extended memory window, sleep transition

    Empathy
    Other's emotional state simulated in self
    Other-emotion: +3 to +5σ
    Affective resonance: -20 to -30%
     1.5-2.5 (somatic simulation)
    Insula-mediated somatic mapping, shared feeling

    Sympathy
    Other's distress recognized, concern generated
    Other-distress: +2 to +3σ
    Personal distress: +15 to +25% (protected)
     1.0-1.2 (limited somatic mirroring)
    Sustainable care without overwhelm

    Belonging
    Social inclusion predictions confirmed
    Inclusion signals: +2 to +4σ
    Group-relevant: -15 to -25%
     1.2-1.5 (safety/warmth felt)
    Reduced social vigilance, oxytocin-sustained

    Rejection
    Social exclusion, large social PE
    Social-threat: +3 to +5σ
    Threat: -20 to -35%
     1.3-1.7 (social pain)
    dACC activation, pain system overlap

    Trust
    Positive social priors, vulnerability accepted
    Betrayal: -2 to -3σ (reduced vigilance)
    Threat/suspicion: +20 to +30% (filtered)
     1.0-1.2
    Computational commitment, oxytocin-mediated

    Focus
    Singular, task-aligned
    Task: +3 to +5σ; Distractor: <0.5σ
    Task: -10 to -15%; Distractor: +10 to +15%
     1.0-1.2
    Tuned filter, LC-NE signal-to-noise optimization

    Creativity
    Loosened constraints, remote associations
    Remote/weak associations: +2 to +4σ
    Novel combinations: -10 to -20%
     0.9-1.1
    Near-critical dynamics, DMN-ECN coupling

    Decision Fatigue
    Model comparison impaired
    Equal across options (dysregulated)
    Elevated: +25 to +40% (resource conservation)
     1.0-1.2
    Glucose depletion, prefrontal exhaustion

    Cognitive Dissonance
    Incompatible high-precision models
    Competing models (each >3σ, mutually inconsistent)
    Unstable: ±20-30% oscillation
     1.2-1.6 (discomfort arousal)
    ACC conflict signal, aversive instability

    Hyperfocus
    Locked on single target, automatic
    Task: +5 to +8σ (extreme); Other: <0.2σ
    Task: -30 to -50%; Other: elevated
     0.8-1.0 (metacognition suppressed)
    Time distortion, complete absorption, post-crash

    Hunger
    Homeostatic deficit (caloric)
    Interoceptive: +2 to +4σ
    Non-food: +15 to +30%; Food: -20%
     1.3-1.8 (gastric/metabolic signals)
    Ghrelin-mediated, attentional hijacking

    Thirst
    Homeostatic deficit (hydration)
    Interoceptive: +2 to +3σ
    Non-water: +15 to +25%; Water: -15 to -20%
     1.2-1.5 (osmotic signals)
    Angiotensin signaling, cognitive impairment


    """

    var body: some View {
        EnhancedContentCard(
            title: "APGI Parameters → Psychological States",
            content: self.mappingBody,
            category: SectionCategory.cognitive,
            hasDataTable: true
        )
        .padding()
    }
}

#Preview {
    ApgiToPsyStateView()
}
