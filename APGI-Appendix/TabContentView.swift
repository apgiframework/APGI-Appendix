import SwiftUI

struct TabContentView: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    
    var body: some View {
        Group {
            switch tab {
            case .methodology:
                MethodologyView()
            case .mathematicalModel:
                MathematicalModelView()
            case .apgiMapping:
                ApgiMappingView()
            case .parameterIdentifiability:
                ParameterIdentifiabilityView()
            case .biologicalImplementation:
                BiologicalImplementationView()
            case .neuromodulatorEffects:
                NeuromodulatorEffectsView()
            case .neuromodulatoryImplementation:
                NeuromodulatoryImplementationView()
            case .explicitNeuromodulator:
                ExplicitNeuromodulatorsView()
            case .mappingCognitiveToApgi:
                MappingCognitiveToApgiView()
            case .apgiToCognitive:
                ApgiToCognitiveView()
            case .psychologicalStates:
                PsychologicalStatesView()
            case .apgiToPsyState:
                ApgiToPsyStateView()
            case .ignitionTimeline:
                IgnitionTimelineView()
            case .neuromodulatoryControl:
                NeuromodulatoryControlsView()
            case .psychiatricDisorders:
                PsychiatricDisordersView()
            case .apgiStatement:
                APGIStatementView()
            case .lifeStages:
                LifeStagesView()
            case .thermodynamicEfficiency:
                ThermodynamicEfficiencyView()
            case .epistemicStandards:
                EpistemicStandardsView()
            case .bibliography:
                BibliographyView()
            case .glossary:
                GlossaryView()
            }
        }
    }
}

#Preview {
    TabContentView(tab: .methodology, selectedTab: .constant(.methodology))
}
