import SwiftUI
import Combine

@MainActor
final class HelpManager: ObservableObject {
    @Published var remoteHelpContent: String = ""
    @Published var isLoading = false
    @Published var lastError: NetworkError?
    @Published var helpSections: [HelpSection] = []
    
    private let networkManager = NetworkManager.shared
    
    struct HelpSection: Identifiable, Codable {
        let id = UUID()
        let title: String
        let content: String
        let category: String
        let lastUpdated: String
        
        enum CodingKeys: String, CodingKey {
            case title, content, category, lastUpdated
        }
    }
    
    func fetchRemoteHelp() async {
        guard let url = networkManager.validateURL("https://api.apgi-framework.org/help.json") else {
            lastError = .invalidURL
            return
        }
        
        isLoading = true
        lastError = nil
        
        do {
            let data = try await networkManager.fetchExternalResourceWithFallback(
                primaryURL: url,
                fallbackURL: networkManager.validateURL("https://raw.githubusercontent.com/apgi/framework/main/help.json")
            )
            
            let decoder = JSONDecoder()
            helpSections = try decoder.decode([HelpSection].self, from: data)
            
            // Combine all help content into a single string for display
            remoteHelpContent = helpSections.map { section in
                """
                # \(section.title)
                
                \(section.content)
                
                ---
                """
            }.joined(separator: "\n\n")
            
        } catch let error as NetworkError {
            lastError = error
        } catch {
            lastError = .unknown(error)
        }
        
        isLoading = false
    }
    
    func getCombinedHelpContent() -> String {
        let localHelp = getLocalHelpContent()
        
        if !remoteHelpContent.isEmpty {
            return localHelp + "\n\n--- Latest Online Help ---\n\n" + remoteHelpContent
        }
        
        return localHelp
    }
    
    private func getLocalHelpContent() -> String {
        return """
        # APGI Framework Help
        
        ## Quick Start
        
        1. **Navigation**: Use the sidebar to browse categories
        2. **Search**: Press ⌘F to search all content
        3. **Bookmarks**: Press ⌘B to bookmark current section
        4. **Focus Mode**: Click the eye icon for distraction-free reading
        
        ## Keyboard Shortcuts
        
        - ⌘F: Open search
        - ⌘B: Toggle bookmark
        - ⌘1-9: Navigate to tabs
        - ⌘/: Show keyboard shortcuts
        - ⌘G: Toggle glossary
        
        ## Getting Started
        
        The APGI Appendix provides comprehensive information about the Adaptive Precision-Gated Ignition Framework. Start with:
        
        1. **Methodology** - Understand the framework approach
        2. **Glossary** - Learn key terminology
        3. **Timeline** - Explore historical developments
        4. **Neuromodulators** - Study biological implementations
        
        ## Network Features
        
        When connected to the internet, the app can fetch:
        - Updated glossary terms
        - Latest bibliography entries
        - App updates
        - Online help documentation
        
        Configure network settings in Preferences > Network.
        
        ## Need More Help?
        
        Check the User Guide for detailed information about all features and navigation.
        """
    }
}

struct HelpView: View {
    @StateObject private var helpManager = HelpManager()
    @State private var showRemoteOnly = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Help & Documentation")
                    .font(.title.bold())
                
                Spacer()
                
                Toggle("Online Only", isOn: $showRemoteOnly)
                    .toggleStyle(.switch)
                    .disabled(helpManager.remoteHelpContent.isEmpty)
                
                Button("Refresh") {
                    Task {
                        await helpManager.fetchRemoteHelp()
                    }
                }
                .disabled(helpManager.isLoading)
            }
            .padding()
            .background(.thinMaterial)
            
            if helpManager.isLoading {
                ProgressView("Loading online help...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = helpManager.lastError {
                VStack(spacing: 16) {
                    Text("Network Error")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await helpManager.fetchRemoteHelp()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let content = showRemoteOnly ? helpManager.remoteHelpContent : helpManager.getCombinedHelpContent()
                        
                        if content.isEmpty {
                            Text("No help content available")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            LazyGlossaryHighlightedContent(text: content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await helpManager.fetchRemoteHelp()
        }
    }
}

struct HelpSectionView: View {
    let section: HelpManager.HelpSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.title)
                    .font(.headline)
                
                Spacer()
                
                Text("Updated: \(section.lastUpdated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(section.content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary.opacity(0.5))
        .cornerRadius(8)
    }
}
