import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case methodology = "Methodology for Consciousness Theories"
    case mathematicalModel = "Mathematical Model"
    case apgiMapping = "APGI Explicit Mapping"
    case parameterIdentifiability = "Parameter Identifiability and the Reduced Model"
    case biologicalImplementation = "Biological Implementation: Explicit Mapping"
    case neuromodulatorEffects = "Neuromodulator Effects on APGI Model State Variables"
    case neuromodulatoryImplementation = "Neuromodulatory Implementation of APGI Control Parameters"
    case explicitNeuromodulator = "Explicit Neuromodulator Mapping"
    case mappingCognitiveToApgi = "Mapping Cognitive Constructs→ APGI"
    case apgiToCognitive = "APGI Parameters → Cognitive Constructs"
    case psychologicalStates = "Psychological States"
    case apgiToPsyState = "APGI Parameters → Psychological States"
    case ignitionTimeline = "Ignition Timeline"
    case neuromodulatoryControl = "Neuromodulatory Control System"
    case psychiatricDisorders = "APGI for Psychiatric Disorders"
    case disordersConditions = "APGI Parameter Table — Disorders & Conditions"
    case apgiStatement = "APGI Statement about Consciousness"
    case lifeStages = "APGI Parameters Across Life Stages"
    case thermodynamicEfficiency = "Thermodynamic and Evolutionary Efficiency"
    case epistemicStandards = "Epistemic Standards"
    case bibliography = "Bibliography"
    case glossary = "Glossary"
    case apgiSimulator = "APGI Simulator"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .methodology: return "book"
        case .mathematicalModel: return "function"
        case .apgiMapping: return "map"
        case .parameterIdentifiability: return "gearshape"
        case .biologicalImplementation: return "leaf"
        case .neuromodulatorEffects: return "waveform"
        case .neuromodulatoryImplementation: return "slider.horizontal.3"
        case .explicitNeuromodulator: return "brain"
        case .mappingCognitiveToApgi: return "arrow.right"
        case .apgiToCognitive: return "arrow.left"
        case .psychologicalStates: return "brain.head.profile"
        case .apgiToPsyState: return "arrow.up.left.and.arrow.down.right"
        case .ignitionTimeline: return "clock"
        case .neuromodulatoryControl: return "switch.2"
        case .psychiatricDisorders: return "cross.case"
        case .disordersConditions: return "tablecells"
        case .apgiStatement: return "brain.head.profile"
        case .lifeStages: return "person.2"
        case .thermodynamicEfficiency: return "flame"
        case .epistemicStandards: return "checkmark.seal"
        case .bibliography: return "books.vertical"
        case .glossary: return "character.book.closed"
        case .apgiSimulator: return "waveform.path.ecg.rectangle"
        }
    }

    var category: SectionCategory {
        switch self {
        case .methodology, .apgiStatement, .epistemicStandards:
            return .theoretical
        case .mathematicalModel, .apgiMapping, .parameterIdentifiability:
            return .mathematical
        case .ignitionTimeline, .apgiSimulator:
            return .navigation
        case .biologicalImplementation, .neuromodulatorEffects,
             .neuromodulatoryImplementation, .explicitNeuromodulator,
             .neuromodulatoryControl:
            return .biological
        case .mappingCognitiveToApgi, .apgiToCognitive, .psychologicalStates, .apgiToPsyState:
            return .cognitive
        case .psychiatricDisorders, .disordersConditions, .lifeStages, .thermodynamicEfficiency:
            return .applications
        case .glossary, .bibliography:
            return .reference
        }
    }

    var shortTitle: String {
        switch self {
        case .methodology: return "Methodology"
        case .mathematicalModel: return "Mathematical Model"
        case .apgiMapping: return "APGI Mapping"
        case .parameterIdentifiability: return "Parameter Identifiability"
        case .biologicalImplementation: return "Biological Implementation"
        case .neuromodulatorEffects: return "Neuromodulator Effects"
        case .neuromodulatoryImplementation: return "Neuromodulatory Implementation"
        case .explicitNeuromodulator: return "Explicit Neuromodulator"
        case .mappingCognitiveToApgi: return "Mapping Cognitive → APGI"
        case .apgiToCognitive: return "APGI → Cognitive"
        case .psychologicalStates: return "Psychological States"
        case .apgiToPsyState: return "APGI → Psychological States"
        case .ignitionTimeline: return "Ignition Timeline"
        case .neuromodulatoryControl: return "Neuromodulatory Control"
        case .psychiatricDisorders: return "Psychiatric Disorders"
        case .disordersConditions: return "Disorders & Conditions"
        case .apgiStatement: return "APGI Statement"
        case .lifeStages: return "Life Stages"
        case .thermodynamicEfficiency: return "Thermodynamic Efficiency"
        case .epistemicStandards: return "Epistemic Standards"
        case .bibliography: return "Bibliography"
        case .glossary: return "Glossary"
        case .apgiSimulator: return "APGI Simulator"
        }
    }

    var hasTables: Bool {
        switch self {
        case .biologicalImplementation, .neuromodulatorEffects,
             .explicitNeuromodulator, .ignitionTimeline, .lifeStages,
             .psychologicalStates, .apgiToPsyState, .disordersConditions:
            return true
        default:
            return false
        }
    }

    var searchIndexText: String {
        switch self {
        case .methodology:
            return "Methodology\n" +
                "The persistent challenges in the field are the pitfalls of vague assertions, implicit assumptions and unfalsifiable claims that have long hindered progress."
        case .mathematicalModel:
            return "Mathematical Model\n" +
                "The Allostatic Precision-Gated Ignition Framework provides a quantitative framework for understanding the dynamics of conscious access."
        case .apgiMapping:
            return "APGI Explicit Mapping\nSurprise (Sₜ)\nIgnition Threshold (θₜ)\nIgnition Probability (Bₜ)\nPrecision-Weighted Surprise\nThalamic Reticular Nucleus\nLocus Coeruleus–Norepinephrine"
        case .parameterIdentifiability:
            return rawValue
        case .biologicalImplementation:
            return rawValue
        case .neuromodulatorEffects:
            return rawValue
        case .neuromodulatoryImplementation:
            return rawValue
        case .explicitNeuromodulator:
            return rawValue
        case .mappingCognitiveToApgi:
            return rawValue
        case .apgiToCognitive:
            return rawValue
        case .psychologicalStates:
            return "Psychological States\nFlow state\nJoy/Happiness\nGratitude\nHope\nOptimism\nAwe\nInspiration\nSerenity\nPride\nAmusement\nLove\nCuriosity\nEngagement\nMindfulness\nNeutrality\nBoredom\nDaydreaming\nDistraction\nFatigue\nAnxiety\nStress\nDepression\nAnger\nFear\nGuilt\nShame\nLoneliness\nFrustration\nConfusion"
        case .apgiToPsyState:
            return "APGI Parameters → Psychological States\nPrediction Error (ε)\nPrecision (π)\nThreshold (θₜ)\nSomatic Bias (β)\nFlow state\nJoy/Happiness\nGratitude\nHope\nOptimism\nAwe\nInspiration\nSerenity\nPride\nAmusement\nLove\nCuriosity\nEngagement\nMindfulness\nNeutrality\nBoredom\nDaydreaming\nDistraction\nFatigue\nAnxiety\nStress\nDepression\nAnger\nFear\nGuilt\nShame\nLoneliness\nFrustration\nConfusion\nDisgust\nEnvy\nJealousy\nRegret\nPessimism\nOverwhelm\nDissociation\nTrance\nHallucination\nDéjà Vu\nHypnagogia\nEmpathy\nSympathy\nBelonging\nRejection\nTrust\nFocus\nCreativity\nDecision Fatigue\nCognitive Dissonance\nHyperfocus\nHunger\nThirst"
        case .ignitionTimeline:
            return "Ignition Timeline\nTrigger\nAmplification\nSalience Broadcast\nConsolidation\nIgnition Confirmation\nMemory & Report\nRefractory Initiation\nTemporal Integration\nThalamocortical\nP3a\nP3b\nGamma"
        case .neuromodulatoryControl:
            return rawValue
        case .psychiatricDisorders:
            return rawValue
        case .disordersConditions:
            return "APGI Parameter Table — Disorders & Conditions\n" +
                "Disorder\n" +
                "Prediction Error ε (σ)\n" +
                "Precision π (dominant channels)\n" +
                "Threshold θₜ (%)\n" +
                "Somatic Bias β\n" +
                "ADHD\nAutism Spectrum Disorder\nSchizophrenia\nMajor Depressive Disorder\nGeneralized Anxiety Disorder\nPTSD"
        case .apgiStatement:
            return rawValue
        case .lifeStages:
            return "APGI Parameters Across Life Stages\nInfancy\nEarly Childhood\nPrimary School Age\nAdolescence\nAdulthood\nAging\nThreshold (θ)\nPrecision Weighting (Π)\nWorking Memory Capacity"
        case .thermodynamicEfficiency:
            return rawValue
        case .epistemicStandards:
            return rawValue
        case .bibliography:
            return rawValue
        case .glossary:
            return rawValue
        case .apgiSimulator:
            return rawValue
        }
    }

    var content: String {
        self.fullContent
    }

    var fullContent: String {
        switch self {
        case .methodology:
            return """
            Methodology for Consciousness Theories

            The persistent challenges in the field are the pitfalls of vague assertions, implicit assumptions
            and unfalsifiable claims that have long hindered progress. Theoretical frameworks of consciousness
            research must be grounded in precise, testable formulations that can be empirically validated
            or refuted.

            The Allostatic Precision-Gated Ignition (APGI) framework addresses these fundamental issues
            by providing a mathematically rigorous, biologically plausible model that can generate
            specific, falsifiable predictions about conscious access and its neural correlates.

            Key methodological principles:
            1. Quantitative precision in parameter definitions
            2. Clear mapping between mathematical formulations and neural mechanisms  
            3. Testable predictions that can be empirically verified
            4. Falsifiability criteria for theoretical claims
            5. Integration across multiple levels of analysis (molecular, cellular, network, systems)
            """
        case .mathematicalModel:
            return """
            Mathematical Model

            The Allostatic Precision-Gated Ignition Framework provides a quantitative framework for understanding the dynamics of conscious access.

            Core mathematical formulation:
            - Prediction error: εₜ = |xₜ - μₜ|
            - Precision weighting: πₜ = exp(-αεₜ²)  
            - Ignition threshold: θₜ = θ₀ + β·Sₜ₋₁
            - Ignition probability: Bₜ = σ(πₜ·εₜ - θₜ)

            These equations capture the essential dynamics of how precision-weighted prediction errors
            compete against adaptive ignition thresholds to determine whether information gains conscious access.
            """
        case .apgiMapping:
            return """
            APGI Explicit Mapping

            Core Components:
            - Surprise (Sₜ): Quantifies prediction error magnitude
            - Ignition Threshold (θₜ): Adaptive barrier for conscious access
            - Ignition Probability (Bₜ): Likelihood of conscious ignition
            - Precision-Weighted Surprise: Error signals modulated by confidence
            - Thalamic Reticular Nucleus: Gating mechanism for sensory flow
            - Locus Coeruleus–Norepinephrine: Neuromodulatory precision control

            The mapping provides explicit correspondence between computational variables and
            neurobiological substrates, enabling empirical testing of framework predictions.
            """
        case .parameterIdentifiability:
            return """
            Parameter Identifiability and the Reduced Model

            Analysis of which APGI parameters can be uniquely identified from observable data
            and development of reduced models that maintain essential dynamics while improving
            parameter estimation reliability.
            """
        case .biologicalImplementation:
            return """
            Biological Implementation: Explicit Mapping

            Detailed mapping of APGI computational components onto known neural circuits and
            molecular mechanisms. Includes thalamocortical loops, neuromodulatory systems,
            and specific cellular implementations of precision-weighted prediction error processing.
            """
        case .neuromodulatorEffects:
            return """
            Neuromodulator Effects on APGI Model State Variables

            Comprehensive analysis of how different neuromodulators (acetylcholine, norepinephrine,
            dopamine, serotonin) influence precision weighting, threshold adaptation, and
            ignition dynamics in the APGI framework.
            """
        case .neuromodulatoryImplementation:
            return """
            Neuromodulatory Implementation of APGI Control Parameters

            Implementation details for how neuromodulatory systems realize the adaptive
            control of precision and threshold parameters in biological neural networks.
            """
        case .explicitNeuromodulator:
            return """
            Explicit Neuromodulator Mapping

            Direct mapping between specific neuromodulatory receptors, intracellular signaling
            pathways, and their computational effects on APGI model parameters.
            """
        case .mappingCognitiveToApgi:
            return """
            Mapping Cognitive Constructs → APGI

            Systematic mapping of psychological constructs (attention, working memory, cognitive
            control) onto APGI computational parameters and dynamics.
            """
        case .apgiToCognitive:
            return """
            APGI Parameters → Cognitive Constructs

            Inverse mapping showing how APGI computational states correspond to measurable
            cognitive phenomena and subjective experiences.
            """
        case .psychologicalStates:
            return """
            Psychological States

            Comprehensive mapping of psychological states onto APGI parameter space:

            Positive states:
            - Flow state: High precision, optimal threshold, low somatic bias
            - Joy/Happiness: Moderate precision, lowered threshold, positive valence bias
            - Gratitude: High social precision, balanced threshold
            - Hope: Future-oriented precision, adaptive threshold
            - Optimism: Positive prediction precision, resilient threshold
            - Awe: High surprise precision, expanded threshold
            - Inspiration: Creative precision, flexible threshold
            - Serenity: Low prediction error, stable precision
            - Pride: Achievement precision, moderate threshold
            - Amusement: Novelty precision, playful threshold
            - Love: Social bonding precision, open threshold
            - Curiosity: Exploratory precision, learning threshold
            - Engagement: Task-focused precision, optimal threshold
            - Mindfulness: Metacognitive precision, balanced threshold

            Neutral states:
            - Neutrality: Balanced precision and threshold
            - Boredom: Low precision, elevated threshold
            - Daydreaming: Internal precision, reduced external threshold
            - Distraction: Fragmented precision, variable threshold
            - Fatigue: Low precision, high threshold

            Negative states:
            - Anxiety: High precision, low threshold, threat bias
            - Stress: Elevated precision, lowered threshold
            - Depression: Low precision, high threshold, negative bias
            - Anger: High precision, very low threshold, action bias
            - Fear: Maximum precision, minimal threshold, survival bias
            - Guilt: Social precision, self-referential threshold
            - Shame: Social precision, withdrawal threshold
            - Loneliness: Social isolation precision, connection threshold
            - Frustration: Goal precision, blocked action threshold
            - Confusion: Low precision, disordered threshold
            """
        case .apgiToPsyState:
            return """
            APGI Parameters → Psychological States

            Detailed mapping of APGI computational parameters to specific psychological states:

            Core parameters:
            - Prediction Error (ε): Mismatch between expected and actual sensory input
            - Precision (π): Confidence weighting of prediction errors
            - Threshold (θₜ): Adaptive barrier for conscious access
            - Somatic Bias (β): Bodily state influence on perception

            State mappings:
            Flow state: Low ε, high π, optimal θₜ, balanced β
            Joy/Happiness: Moderate ε, high π, lowered θₜ, positive β
            Gratitude: Social ε, high π, balanced θₜ, prosocial β
            Hope: Future ε, adaptive π, flexible θₜ, optimistic β
            Optimism: Positive ε, resilient π, stable θₜ, growth β
            Awe: High ε, expansive π, elevated θₜ, transcendent β
            Inspiration: Creative ε, flexible π, dynamic θₜ, innovative β
            Serenity: Low ε, stable π, balanced θₜ, calm β
            Pride: Achievement ε, focused π, moderate θₜ, confident β
            Amusement: Novel ε, playful π, variable θₜ, joyful β
            Love: Social ε, bonding π, open θₜ, connecting β
            Curiosity: Exploratory ε, learning π, discovery θₜ, inquisitive β
            Engagement: Task ε, optimal π, focused θₜ, absorbed β
            Mindfulness: Metacognitive ε, balanced π, centered θₜ, aware β

            Neutral states:
            Neutrality: Balanced ε, moderate π, stable θₜ, centered β
            Boredom: Low ε, reduced π, elevated θₜ, understimulated β
            Daydreaming: Internal ε, imaginative π, lowered θₜ, introspective β
            Distraction: Fragmented ε, scattered π, variable θₜ, unfocused β
            Fatigue: Low ε, depleted π, high θₜ, exhausted β

            Negative states:
            Anxiety: High ε, elevated π, low θₜ, threat β
            Stress: Elevated ε, high π, lowered θₜ, pressure β
            Depression: Low ε, reduced π, high θₜ, negative β
            Anger: High ε, focused π, minimal θₜ, action β
            Fear: Maximum ε, peak π, minimal θₜ, survival β
            Guilt: Social ε, self-focused π, withdrawal θₜ, moral β
            Shame: Social ε, self-focused π, isolation θₜ, social β
            Loneliness: Social ε, isolation π, connection θₜ, separation β
            Frustration: Goal ε, blocked π, obstacle θₜ, impediment β
            Confusion: Disordered ε, chaotic π, unstable θₜ, uncertainty β
            Disgust: Contamination ε, avoidance π, rejection θₜ, repulsion β
            Envy: Social comparison ε, competitive π, acquisition θₜ, rivalry β
            Jealousy: Relationship ε, protective π, defensive θₜ, possessive β
            Regret: Past ε, corrective π, learning θₜ, improvement β
            Pessimism: Negative ε, rigid π, elevated θₜ, defeatist β
            Overwhelm: Excessive ε, saturated π, minimal θₜ, collapse β
            Dissociation: Detachment ε, fragmented π, disconnection θₜ, separation β
            Trance: Altered ε, focused π, specialized θₜ, absorbed β
            Hallucination: Internal ε, high π, lowered θₜ, perceptual β
            Déjà Vu: Memory ε, recognition π, familiarity θₜ, temporal β
            Hypnagogia: Transitional ε, dream π, threshold θₜ, sleep β
            Empathy: Social ε, other-focused π, understanding θₜ, compassionate β
            Sympathy: Social ε, affective π, concern θₜ, supportive β
            Belonging: Group ε, social π, inclusion θₜ, community β
            Rejection: Social ε, exclusion π, isolation θₜ, separation β
            Trust: Relational ε, secure π, openness θₜ, confidence β
            Focus: Task ε, concentrated π, optimal θₜ, attention β
            Creativity: Novel ε, flexible π, expansive θₜ, innovation β
            Decision Fatigue: Choice ε, depleted π, elevated θₜ, exhaustion β
            Cognitive Dissonance: Conflict ε, resolution π, integration θₜ, harmony β
            Hyperfocus: Target ε, intense π, exclusive θₜ, absorption β
            Hunger: Bodily ε, homeostatic π, survival θₜ, need β
            Thirst: Bodily ε, homeostatic π, survival θₜ, need β
            """
        case .ignitionTimeline:
            return """
            Ignition Timeline

            Sequential stages of conscious access in the APGI framework:

            1. Trigger: Initial prediction error detection
            2. Amplification: Precision-weighted error signal enhancement
            3. Salience Broadcast: Global workspace activation
            4. Consolidation: Memory encoding and stabilization
            5. Ignition Confirmation: Conscious access verification
            6. Memory & Report: Subjective report formation
            7. Refractory Initiation: Post-ignition recovery period

            Neural correlates:
            - Temporal Integration: 200-400ms window
            - Thalamocortical: Recurrent processing loops
            - P3a: Novelty detection component
            - P3b: Conscious access component
            - Gamma: Synchronous binding frequency
            """
        case .neuromodulatoryControl:
            return """
            Neuromodulatory Control System

            Implementation of adaptive control mechanisms for APGI parameters through
            neuromodulatory systems. Includes feedback loops, gain control, and
            state-dependent modulation of precision and threshold parameters.
            """
        case .psychiatricDisorders:
            return """
            APGI for Psychiatric Disorders

            Application of the APGI framework to understanding psychiatric disorders
            through the lens of altered precision weighting, threshold dysregulation,
            and maladaptive prediction error processing.
            """
        case .disordersConditions:
            return """
            APGI Parameter Table — Disorders & Conditions

            Disorder | Prediction Error ε (σ) | Precision π (dominant channels) | Threshold θₜ (%) | Somatic Bias β
            ---|---|---|---|---
            ADHD | Elevated σ | Auditory/Visual π | 65% | High β (motor)
            Autism Spectrum Disorder | Variable σ | Sensory π (hyper) | 80% | Low β (interoceptive)
            Schizophrenia | Disordered σ | Dopaminergic π | 45% | Erratic β
            Major Depressive Disorder | Low σ | Reduced π | 85% | Negative β
            Generalized Anxiety Disorder | High σ | Threat π | 40% | High β (danger)
            PTSD | Trauma σ | Hypervigilant π | 35% | Extreme β (threat)
            """
        case .apgiStatement:
            return """
            APGI Statement about Consciousness

            The Allostatic Precision-Gated Ignition framework provides a comprehensive,
            mathematically rigorous account of conscious access that integrates prediction
            error processing, precision weighting, and adaptive threshold mechanisms
            to explain the dynamics of conscious experience and its neural correlates.
            """
        case .lifeStages:
            return """
            APGI Parameters Across Life Stages

            Life Stage | Threshold (θ) | Precision Weighting (Π) | Working Memory Capacity
            ---|---|---|---
            Infancy | 8-9/10 | High sensory, low cognitive | 1-2 items
            Early Childhood | 7/10 | Balanced sensory-cognitive | 3-4 items
            Primary School Age | 6/10 | Developing cognitive precision | 4-5 items
            Adolescence | 5/10 | Variable precision (social/emotional) | 5-7 items
            Adulthood | 4/10 | Optimized cognitive precision | 7-9 items
            Aging | 6/10 | Compromised precision, adaptive threshold | 5-6 items
            """
        case .thermodynamicEfficiency:
            return """
            Thermodynamic and Evolutionary Efficiency

            Analysis of the APGI framework from thermodynamic and evolutionary perspectives,
            examining energy efficiency, information processing optimization, and
            adaptive advantages of precision-gated conscious access.
            """
        case .epistemicStandards:
            return """
            Epistemic Standards

            Standards for evidence, methodology, and theoretical claims in consciousness
            research based on the APGI framework's requirements for falsifiability,
            quantitative precision, and empirical testability.
            """
        case .bibliography:
            return """
            Bibliography

            Comprehensive reference list of key papers, books, and resources relevant
            to the APGI framework, consciousness research, computational neuroscience,
            and related methodological approaches.
            """
        case .glossary:
            return """
            Glossary

            Definitions of key terms, concepts, and technical language used in the
            APGI framework and related consciousness research literature.
            """
        case .apgiSimulator:
            return """
            APGI Simulator

            Interactive computational tool for exploring APGI dynamics, parameter
            interactions, and predictions. Provides real-time visualization of
            conscious access processes and allows experimental manipulation of
            framework parameters.
            """
        }
    }

    var view: AnyView {
        switch self {
        case .methodology:
            return AnyView(MethodologyView())
        case .mathematicalModel:
            return AnyView(MathematicalModelView())
        case .apgiMapping:
            return AnyView(ApgiMappingView())
        case .parameterIdentifiability:
            return AnyView(ParameterIdentifiabilityView())
        case .biologicalImplementation:
            return AnyView(BiologicalImplementationView())
        case .neuromodulatorEffects:
            return AnyView(NeuromodulatorEffectsView())
        case .neuromodulatoryImplementation:
            return AnyView(NeuromodulatoryImplementationView())
        case .explicitNeuromodulator:
            return AnyView(ExplicitNeuromodulatorsView())
        case .mappingCognitiveToApgi:
            return AnyView(MappingCognitiveToApgiView())
        case .apgiToCognitive:
            return AnyView(ApgiToCognitiveView())
        case .psychologicalStates:
            return AnyView(PsychologicalStatesView())
        case .apgiToPsyState:
            return AnyView(ApgiToPsyStateView())
        case .ignitionTimeline:
            return AnyView(IgnitionTimelineView())
        case .neuromodulatoryControl:
            return AnyView(NeuromodulatoryControlsView())
        case .psychiatricDisorders:
            return AnyView(PsychiatricDisordersView())
        case .disordersConditions:
            return AnyView(DisordersConditionsView())
        case .apgiStatement:
            return AnyView(APGIStatementView())
        case .lifeStages:
            return AnyView(LifeStagesView())
        case .thermodynamicEfficiency:
            return AnyView(ThermodynamicEfficiencyView())
        case .epistemicStandards:
            return AnyView(EpistemicStandardsView())
        case .bibliography:
            return AnyView(BibliographyView())
        case .glossary:
            return AnyView(GlossaryView())
        case .apgiSimulator:
            return AnyView(APGISimulatorView())
        }
    }
}

enum NavigationSection: String, CaseIterable, Identifiable, Hashable {
    case foundations = "Foundations"
    case neurobiology = "Neurobiology"
    case cognition = "Cognition & Psychology"
    case clinical = "Clinical Applications"
    case navigation = "Demonstrations"
    case reference = "Reference"

    var id: String {
        rawValue
    }

    var tabs: [Tab] {
        switch self {
        case .foundations:
            return [.methodology, .mathematicalModel, .apgiMapping,
                    .parameterIdentifiability, .apgiStatement]
        case .neurobiology:
            return [.biologicalImplementation, .neuromodulatorEffects,
                    .neuromodulatoryImplementation, .explicitNeuromodulator,
                    .neuromodulatoryControl]
        case .cognition:
            return [.mappingCognitiveToApgi, .apgiToCognitive,
                    .psychologicalStates, .apgiToPsyState, .lifeStages]
        case .clinical:
            return [.psychiatricDisorders, .disordersConditions]
        case .navigation:
            return [.ignitionTimeline, .apgiSimulator]
        case .reference:
            return [.glossary, .bibliography, .epistemicStandards,
                    .thermodynamicEfficiency]
        }
    }
}

extension NavigationSection {
    var icon: String {
        switch self {
        case .foundations: return "book"
        case .neurobiology: return "brain.head.profile"
        case .cognition: return "brain"
        case .clinical: return "stethoscope"
        case .navigation: return "location"
        case .reference: return "books.vertical.fill"
        }
    }

    var color: Color {
        switch self {
        case .foundations: return .apgiBlue
        case .neurobiology: return .apgiGreen
        case .cognition: return .apgiOrange
        case .clinical: return .apgiRed
        case .navigation: return .accentColor
        case .reference: return .gray
        }
    }
}
