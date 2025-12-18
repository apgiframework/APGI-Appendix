import SwiftUI

struct SettingsView: View {
    @AppStorage("contentFontSize") private var fontSize: Double = 15.0
    @AppStorage("sidebarVisible") private var sidebarVisible: Bool = true
    @AppStorage("focusModeEnabled") private var focusModeEnabled: Bool = false
    @AppStorage("autoSaveBookmarks") private var autoSaveBookmarks: Bool = true
    @AppStorage("enableAnimations") private var enableAnimations: Bool = true
    @AppStorage("darkMode") private var darkMode: Bool = false
    
    var body: some View {
        TabView {
            // General Settings
            VStack(alignment: .leading, spacing: 20) {
                Text("General")
                    .font(.title2.bold())
                    .padding(.bottom)
                
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size")
                        .font(.headline)
                    
                    HStack {
                        Slider(value: $fontSize, in: 10...24, step: 1)
                        Text("\(Int(fontSize))pt")
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                
                // Sidebar
                Toggle("Show Sidebar by Default", isOn: $sidebarVisible)
                
                // Focus Mode
                Toggle("Enable Focus Mode", isOn: $focusModeEnabled)
                
                // Animations
                Toggle("Enable Animations", isOn: $enableAnimations)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // Appearance
            VStack(alignment: .leading, spacing: 20) {
                Text("Appearance")
                    .font(.title2.bold())
                    .padding(.bottom)
                
                // Dark Mode
                Toggle("Dark Mode", isOn: $darkMode)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }
            
            // Bookmarks
            VStack(alignment: .leading, spacing: 20) {
                Text("Bookmarks")
                    .font(.title2.bold())
                    .padding(.bottom)
                
                Toggle("Auto-save Bookmarks", isOn: $autoSaveBookmarks)
                
                Button("Clear All Bookmarks") {
                    clearAllBookmarks()
                }
                .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }
            
            // About
            VStack(alignment: .leading, spacing: 20) {
                Text("About APGI Framework")
                    .font(.title2.bold())
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version: 1.0.0")
                    Text("Build: 2024.1")
                    Text("© 2024 APGI Research Team")
                }
                
                Divider()
                
                Text("The Adaptive Precision-Gated Ignition (APGI) Framework provides a comprehensive computational model of conscious access, integrating predictive coding, precision weighting, and metabolic constraints.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func clearAllBookmarks() {
        // Implementation to clear all bookmarks
        UserDefaults.standard.removeObject(forKey: "bookmarkedTabs")
    }
}

#Preview {
    SettingsView()
}
