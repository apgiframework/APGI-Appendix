import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    @State private var selectedTab: Tab = .methodology
    @State private var searchPresented: Bool = false
    @State private var focusModeEnabled: Bool = false
    @StateObject private var bookmarkManager = BookmarkManager()
    @AppStorage("sidebarVisible") private var sidebarVisible: Bool = true
    
    var body: some View {
        NavigationSplitView(columnVisibility: sidebarVisibilityBinding) {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            ZStack {
                TabContentView(tab: selectedTab, selectedTab: $selectedTab)

                if focusModeEnabled {
                    FocusModeView(
                        isEnabled: $focusModeEnabled,
                        content: selectedTab.content,
                        title: selectedTab.rawValue
                    )
                }

                if searchPresented {
                    SearchView(isPresented: $searchPresented) { tab in
                        selectedTab = tab
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    BookmarkButton(tab: selectedTab)

                    Button {
                        focusModeEnabled.toggle()
                    } label: {
                        Image(systemName: "eye")
                    }
                    .apgiAccessibility(
                        label: "Focus mode",
                        hint: focusModeEnabled ? "Exit focus mode" : "Enter focus mode",
                        traits: .isButton
                    )

                    Button {
                        searchPresented.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: [.command])
                    .apgiAccessibility(
                        label: "Search",
                        hint: "Search all content",
                        traits: .isButton
                    )

                    ExportButton(tab: selectedTab, content: selectedTab.content)

                    FontSizeControl()
                }
            }
        }
        .environmentObject(bookmarkManager)
        .frame(minWidth: 1000, minHeight: 700)
    }

    private var sidebarVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { sidebarVisible ? .all : .detailOnly },
            set: { newValue in
                sidebarVisible = (newValue != .detailOnly)
            }
        )
    }
}

final class BookmarkManager: ObservableObject {
    @Published private(set) var bookmarkedTabs: Set<Tab> = []

    func toggle(_ tab: Tab) {
        if bookmarkedTabs.contains(tab) {
            bookmarkedTabs.remove(tab)
        } else {
            bookmarkedTabs.insert(tab)
        }
    }

    func isBookmarked(_ tab: Tab) -> Bool {
        bookmarkedTabs.contains(tab)
    }
}

struct BookmarkButton: View {
    @EnvironmentObject private var bookmarkManager: BookmarkManager
    let tab: Tab

    var body: some View {
        Button {
            bookmarkManager.toggle(tab)
        } label: {
            Image(systemName: bookmarkManager.isBookmarked(tab) ? "bookmark.fill" : "bookmark")
        }
        .apgiAccessibility(
            label: "Bookmark",
            hint: bookmarkManager.isBookmarked(tab) ? "Remove bookmark" : "Add bookmark",
            traits: .isButton
        )
        .keyboardShortcut("b", modifiers: [.command])
    }
}

struct ExportButton: View {
    let tab: Tab
    let content: String

    var body: some View {
        Button {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(content, forType: .string)
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .apgiAccessibility(
            label: "Export",
            hint: "Copy this section to the clipboard",
            traits: .isButton
        )
    }
}

#Preview {
    ContentView()
}