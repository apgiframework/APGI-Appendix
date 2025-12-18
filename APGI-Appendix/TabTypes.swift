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
    case interactiveVisualizations = "Interactive Visualizations"
    case glossary = "Glossary"
    case apgiSimulator = "APGI Simulator"
    
    var id: String { rawValue }
    
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
        case .interactiveVisualizations: return "view.3d"
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
        case .biologicalImplementation, .neuromodulatorEffects,
             .neuromodulatoryImplementation, .explicitNeuromodulator,
             .ignitionTimeline, .neuromodulatoryControl:
            return .biological
        case .mappingCognitiveToApgi, .apgiToCognitive, .psychologicalStates, .apgiToPsyState:
            return .cognitive
        case .psychiatricDisorders, .disordersConditions, .lifeStages, .thermodynamicEfficiency, .interactiveVisualizations, .apgiSimulator:
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
        case .interactiveVisualizations: return "Visualizations"
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
        case .interactiveVisualizations:
            return "Interactive Visualizations\n" +
            "Interactive Neural Visualization\n" +
            "Network Graph\n" +
            "Neuromodulators\n" +
            "Brain regions\n" +
            "3D model\n" +
            "Connectivity\n" +
            "Parameters"
        case .glossary:
            return rawValue
        case .apgiSimulator:
            return rawValue
        }
    }

    var content: String {
        searchIndexText
    }
}
