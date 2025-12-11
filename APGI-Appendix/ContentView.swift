import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .methodology
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(
                selectedTab: $selectedTab,
                onTabSelected: { tab in
                    selectedTab = tab
                }
            )
            
            TabView(selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    TabContentView(tab: tab, selectedTab: $selectedTab)
                        .tabItem {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                        .tag(tab)
                }
            }
            .frame(minWidth: 800, minHeight: 600) // Ensures a reasonable window size for macOS
        }
    }
}

#Preview {
    ContentView()
}
