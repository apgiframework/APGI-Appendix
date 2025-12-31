import SwiftUI

struct TabContentView: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var contentLoadAttempted = false
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                contentView
            }
        }
        .onAppear {
            loadContentIfNeeded()
        }
        .onChange(of: tab) { _, _ in
            loadContentIfNeeded()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading \(tab.shortTitle)...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale))
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Content Load Error")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                loadContentIfNeeded()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Show Fallback") {
                showFallbackContent()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var contentView: some View {
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
            case .psychologicalStates:
                PsychologicalStatesView()
            case .apgiToPsyState:
                ApgiToPsyStateView()
            case .apgiToCognitive:
                ApgiToCognitiveView()
            case .mappingCognitiveToApgi:
                MappingCognitiveToApgiView()
            case .neuromodulatoryControl:
                NeuromodulatoryControlsView()
            case .psychiatricDisorders:
                PsychiatricDisordersView()
            case .disordersConditions:
                DisordersConditionsView()
            case .epistemicStandards:
                EpistemicStandardsView()
            case .ignitionTimeline:
                IgnitionTimelineView()
            case .lifeStages:
                LifeStagesView()
            case .thermodynamicEfficiency:
                ThermodynamicEfficiencyView()
            case .bibliography:
                BibliographyView()
            case .glossary:
                GlossaryView()
            case .apgiStatement:
                APGIStatementView()
            case .apgiSimulator:
                APGISimulatorView()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
        .animation(.easeInOut(duration: 0.3), value: tab)
    }
    
    private func loadContentIfNeeded() {
        guard !contentLoadAttempted else { return }
        
        contentLoadAttempted = true
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Check cache first
                let cacheKey = "content_\(tab.rawValue)"
                if let _ = performanceManager.getCachedContent(for: cacheKey) {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = nil
                    }
                    return
                }
                
                // Determine content type and loading delay
                let contentType = getContentType(tab)
                let loadingDelay = performanceManager.getOptimizedLoadingDelay(for: contentType)
                
                try await Task.sleep(nanoseconds: UInt64(loadingDelay * 1_000_000_000))
                
                // Validate content availability
                guard !tab.content.isEmpty else {
                    throw ContentLoadError.emptyContent
                }
                
                // Cache the content
                let cachedContent = CachedContent(content: tab.content, cost: getContentCost(tab))
                performanceManager.setCachedContent(cachedContent, for: cacheKey)
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func getContentType(_ tab: Tab) -> ContentType {
        switch tab {
        case .methodology, .apgiStatement:
            return .light
        case .mathematicalModel, .apgiMapping, .parameterIdentifiability, .lifeStages:
            return .medium
        case .psychiatricDisorders, .bibliography, .apgiSimulator:
            return .heavy
        case .neuromodulatorEffects, .psychologicalStates, .apgiToPsyState:
            return .critical
        default:
            return .medium
        }
    }
    
    private func getContentCost(_ tab: Tab) -> Int {
        switch getContentType(tab) {
        case .light: return 1
        case .medium: return 3
        case .heavy: return 5
        case .critical: return 10
        }
    }
    
    private func showFallbackContent() {
        errorMessage = nil
        // Fallback content will be shown through the default case
    }
}

enum ContentLoadError: LocalizedError {
    case emptyContent
    case contentUnavailable
    case loadingTimeout
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "No content available for this section."
        case .contentUnavailable:
            return "Content is currently unavailable. Please try again later."
        case .loadingTimeout:
            return "Content loading timed out. Please check your connection and retry."
        }
    }
}

#Preview {
    TabContentView(tab: .methodology, selectedTab: .constant(.methodology))
}
