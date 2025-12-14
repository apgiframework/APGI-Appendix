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
    case ignitionTimeline = "Ignition Timeline"
    case neuromodulatoryControl = "Neuromodulatory Control System"
    case psychiatricDisorders = "APGI for Psychiatric Disorders"
    case apgiStatement = "APGI Statement about Consciousness"
    case lifeStages = "APGI Parameters Across Life Stages"
    case thermodynamicEfficiency = "Thermodynamic and Evolutionary Efficiency"
    case epistemicStandards = "Epistemic Standards"
    case bibliography = "Bibliography"
    case glossary = "Glossary"
    case targetAudience = "Target Audience Profile"
    
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
        case .ignitionTimeline: return "clock"
        case .neuromodulatoryControl: return "switch.2"
        case .psychiatricDisorders: return "cross.case"
        case .apgiStatement: return "brain.head.profile"
        case .lifeStages: return "person.2"
        case .thermodynamicEfficiency: return "flame"
        case .epistemicStandards: return "checkmark.seal"
        case .bibliography: return "books.vertical"
        case .glossary: return "character.book.closed"
        case .targetAudience: return "person.3"
        }
    }
    
    var category: SectionCategory {
        switch self {
        case .methodology, .apgiStatement, .epistemicStandards, .targetAudience:
            return .theoretical
        case .mathematicalModel, .apgiMapping, .parameterIdentifiability:
            return .mathematical
        case .biologicalImplementation, .neuromodulatorEffects,
             .neuromodulatoryImplementation, .explicitNeuromodulator,
             .ignitionTimeline, .neuromodulatoryControl:
            return .biological
        case .mappingCognitiveToApgi, .apgiToCognitive:
            return .cognitive
        case .psychiatricDisorders, .lifeStages, .thermodynamicEfficiency:
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
        case .ignitionTimeline: return "Ignition Timeline"
        case .neuromodulatoryControl: return "Neuromodulatory Control"
        case .psychiatricDisorders: return "Psychiatric Disorders"
        case .apgiStatement: return "APGI Statement"
        case .lifeStages: return "Life Stages"
        case .thermodynamicEfficiency: return "Thermodynamic Efficiency"
        case .epistemicStandards: return "Epistemic Standards"
        case .bibliography: return "Bibliography"
        case .glossary: return "Glossary"
        case .targetAudience: return "Target Audience"
        }
    }
    
    var hasTables: Bool {
        switch self {
        case .biologicalImplementation, .neuromodulatorEffects, 
             .explicitNeuromodulator, .ignitionTimeline, .lifeStages:
            return true
        default:
            return false
        }
    }
}
