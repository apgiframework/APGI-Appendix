import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedTab: Tab = .methodology
    @State private var searchPresented: Bool = false
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var navigationManager = KeyboardNavigationManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationSplitView(columnVisibility: sidebarVisibilityBinding) {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            ZStack {
                TabContentView(tab: selectedTab, selectedTab: $selectedTab)

                if themeManager.focusModeEnabled {
                    FocusModeView(
                        isEnabled: $themeManager.focusModeEnabled,
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
                        themeManager.focusModeEnabled.toggle()
                    } label: {
                        Image(systemName: "eye")
                    }
                    .apgiAccessibility(
                        label: "Focus mode",
                        hint: themeManager.focusModeEnabled ? "Exit focus mode" : "Enter focus mode",
                        traits: .isButton
                    )

                    Button {
                        searchPresented.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .keyboardShortcut("f", modifiers: [.command])
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
        .environmentObject(navigationManager)
        .frame(minWidth: 1000, minHeight: 700)
        .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
            searchPresented = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let tab = notification.object as? Tab {
                selectedTab = tab
                syncNavigationState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
            if let section = notification.object as? String {
                navigateToSection(section)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
            navigateToNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
            navigateToPrevious()
        }
        .onChange(of: selectedTab) { _, newTab in
            syncNavigationState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
            themeManager.sidebarVisible.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            if NSApp.keyWindow != nil {
                NSApp.keyWindow?.contentViewController?.view.scaleUnitSquare(to: NSSize(width: 1.2, height: 1.2))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            if NSApp.keyWindow != nil {
                NSApp.keyWindow?.contentViewController?.view.scaleUnitSquare(to: NSSize(width: 0.8, height: 0.8))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "APGI-Framework-Section.pdf"
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    // Implement PDF export logic here
                    print("Exporting PDF to: \(url)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportCurrentSection)) { _ in
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "\(selectedTab.rawValue).txt"
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    do {
                        try selectedTab.content.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        print("Failed to export section: \(error)")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyCitation)) { _ in
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString("APGI Framework (2024). \(selectedTab.rawValue)", forType: .string)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openHelpGuide)) { _ in
            navigationManager.showKeyboardShortcuts = true
        }
        .sheet(isPresented: $navigationManager.showKeyboardShortcuts) {
            KeyboardShortcutsView(isPresented: $navigationManager.showKeyboardShortcuts)
        }
    }
    
    private func navigateToSection(_ section: String) {
        switch section.lowercased() {
        case "biological":
            selectedTab = .biologicalImplementation
        case "neuromodulators":
            selectedTab = .neuromodulatorEffects
        case "clinical":
            selectedTab = .psychiatricDisorders
        default:
            break
        }
    }
    
    private func navigateToNext() {
        guard let currentIndex = Tab.allCases.firstIndex(of: selectedTab),
              currentIndex < Tab.allCases.count - 1 else { return }
        selectedTab = Tab.allCases[currentIndex + 1]
        syncNavigationState()
    }
    
    private func navigateToPrevious() {
        guard let currentIndex = Tab.allCases.firstIndex(of: selectedTab),
              currentIndex > 0 else { return }
        selectedTab = Tab.allCases[currentIndex - 1]
        syncNavigationState()
    }
    
    private func syncNavigationState() {
        if let index = Tab.allCases.firstIndex(of: selectedTab) {
            navigationManager.currentSectionIndex = index
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard NSApp.keyWindow != nil else { return event }
            
            // Handle Command+1-9 for tab navigation
            if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.control) {
                let keyChar = event.charactersIgnoringModifiers
                if let char = keyChar, char >= "1" && char <= "9" {
                    let tabIndex = Int(char)! - 1
                    if tabIndex < Tab.allCases.count {
                        selectedTab = Tab.allCases[tabIndex]
                        syncNavigationState()
                        return nil
                    }
                }
                
                // Handle Command+/ for keyboard shortcuts
                if keyChar == "/" {
                    navigationManager.showKeyboardShortcuts = true
                    return nil
                }
                
                // Handle Command+G for glossary
                if keyChar == "g" {
                    navigationManager.toggleGlossary()
                    return nil
                }
            }
            
            return event
        }
    }

    private var sidebarVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { themeManager.sidebarVisible ? .all : .detailOnly },
            set: { newValue in
                themeManager.sidebarVisible = (newValue != .detailOnly)
            }
        )
    }
}

final class BookmarkManager: ObservableObject {
    @Published private(set) var bookmarkedTabs: Set<Tab> = []
    private let storageKey = "bookmarkedTabs"
    
    init() {
        loadBookmarks()
        setupNotifications()
    }
    
    private func loadBookmarks() {
        if let bookmarkStrings = UserDefaults.standard.stringArray(forKey: storageKey) {
            bookmarkedTabs = Set(bookmarkStrings.compactMap { Tab(rawValue: $0) })
        }
    }
    
    private func saveBookmarks() {
        let bookmarkStrings = Array(bookmarkedTabs.map { $0.rawValue })
        UserDefaults.standard.set(bookmarkStrings, forKey: storageKey)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .clearAllBookmarks)
            .sink { _ in
                self.bookmarkedTabs.removeAll()
                self.saveBookmarks()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()

    func toggle(_ tab: Tab) {
        if bookmarkedTabs.contains(tab) {
            bookmarkedTabs.remove(tab)
        } else {
            bookmarkedTabs.insert(tab)
        }
        saveBookmarks()
    }

    func isBookmarked(_ tab: Tab) -> Bool {
        bookmarkedTabs.contains(tab)
    }
    
    func clearAll() {
        bookmarkedTabs.removeAll()
        saveBookmarks()
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