import SwiftUI
struct NavigationHeader: View {
    @Binding var selectedTab: Tab
    let onTabSelected: (Tab) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Tab.allCases) { tab in
                    NavigationButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        onTap: { onTabSelected(tab) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .shadow(radius: 1)
    }
}

struct NavigationButton: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Text(shortenedTitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var shortenedTitle: String {
        let title = tab.rawValue
        if title.count <= 20 {
            return title
        }
        
        switch tab {
        case .methodology:
            return "Methodology"
        case .mathematicalModel:
            return "Mathematical Model"
        case .apgiMapping:
            return "APGI Mapping"
        case .parameterIdentifiability:
            return "Parameter Identifiability"
        case .biologicalImplementation:
            return "Biological Implementation"
        case .neuromodulatorEffects:
            return "Neuromodulator Effects"
        case .neuromodulatoryImplementation:
            return "Neuromodulatory Implementation"
        case .explicitNeuromodulator:
            return "Explicit Neuromodulator"
        case .mappingCognitiveToApgi:
            return "Cognitive→APGI"
        case .apgiToCognitive:
            return "APGI→Cognitive"
        case .psychologicalStates:
            return "Psychological States"
        case .apgiToPsyState:
            return "APGI→Psy States"
        case .ignitionTimeline:
            return "Timeline"
        case .neuromodulatoryControl:
            return "Neuromodulatory Control"
        case .psychiatricDisorders:
            return "Psychiatric Disorders"
        case .disordersConditions:
            return "Disorders & Conditions"
        case .apgiStatement:
            return "APGI Statement"
        case .lifeStages:
            return "Life Stages"
        case .thermodynamicEfficiency:
            return "Thermodynamic Efficiency"
        case .epistemicStandards:
            return "Epistemic Standards"
        case .bibliography:
            return "Bibliography"
        case .interactiveVisualizations:
            return "Visualizations"
        case .glossary:
            return "Glossary"
        }
    }
}
