import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .methodology
    @State private var isSearchPresented: Bool = false
    
    init() {
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            TabContentView(tab: selectedTab, selectedTab: $selectedTab)
                .frame(minWidth: 800, minHeight: 600)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isSearchPresented = true
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .keyboardShortcut("k", modifiers: [.command])
                    }
                }
        }
        .sheet(isPresented: $isSearchPresented) {
            SearchView(isPresented: $isSearchPresented) { tab in
                selectedTab = tab
            }
        }
    }
}

#Preview {
    ContentView()
}