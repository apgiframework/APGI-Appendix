import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .methodology
    
    init() {
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            TabContentView(tab: selectedTab, selectedTab: $selectedTab)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}

#Preview {
    ContentView()
}