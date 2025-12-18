import SwiftUI
import AppKit
import Combine

// MARK: - Keyboard Navigation Manager

@MainActor
final class KeyboardNavigationManager: ObservableObject {
    static let shared = KeyboardNavigationManager()
    
    @Published var isSearchFocused = false
    @Published var isGlossaryOpen = false
    @Published var currentSectionIndex = 0
    @Published var showKeyboardShortcuts = false
    
    private init() {}
    
    var allTabs: [Tab] {
        Tab.allCases
    }
    
    func navigateToNextSection() {
        let maxIndex = allTabs.count - 1
        if currentSectionIndex < maxIndex {
            currentSectionIndex += 1
        }
    }
    
    func navigateToPreviousSection() {
        if currentSectionIndex > 0 {
            currentSectionIndex -= 1
        }
    }
    
    func navigateToSection(at index: Int) {
        guard index >= 0 && index < allTabs.count else { return }
        currentSectionIndex = index
    }
    
    func currentTab() -> Tab {
        guard currentSectionIndex < allTabs.count else { return .methodology }
        return allTabs[currentSectionIndex]
    }
    
    func focusSearch() {
        isSearchFocused = true
    }
    
    func toggleGlossary() {
        isGlossaryOpen.toggle()
    }
}

// MARK: - Keyboard Shortcuts Overlay

struct KeyboardShortcutsView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let shortcuts: [(category: String, items: [(key: String, description: String)])] = [
        ("Navigation", [
            ("⌘↑", "Previous section"),
            ("⌘↓", "Next section"),
            ("⌘1-9", "Jump to section 1-9"),
            ("⌘[", "Back in history"),
            ("⌘]", "Forward in history"),
        ]),
        ("Search & Reference", [
            ("⌘F", "Focus search bar"),
            ("⌘G", "Toggle glossary panel"),
            ("⌘⇧G", "Open glossary window"),
            ("Esc", "Close search/panels"),
        ]),
        ("Windows", [
            ("⌘⇧T", "Open timeline window"),
            ("⌘W", "Close current window"),
            ("⌘M", "Minimize window"),
            ("⌘⌃F", "Toggle fullscreen"),
        ]),
        ("Reading", [
            ("⌘+", "Increase font size"),
            ("⌘-", "Decrease font size"),
            ("⌘0", "Reset font size"),
            ("Space", "Scroll down"),
            ("⇧Space", "Scroll up"),
        ]),
        ("General", [
            ("⌘,", "Open settings"),
            ("⌘/", "Show this help"),
            ("⌘Q", "Quit application"),
        ])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("Keyboard Shortcuts")
                    .font(.title2.bold())
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(.bar)
            
            Divider()
            
            // Shortcuts grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 24) {
                    ForEach(shortcuts, id: \.category) { section in
                        shortcutSection(section.category, items: section.items)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func shortcutSection(_ title: String, items: [(key: String, description: String)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.key) { item in
                    HStack(spacing: 12) {
                        Text(item.key)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primary.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text(item.description)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Focusable Search Field

struct FocusableSearchField: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    
    @FocusState private var fieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($fieldFocused)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    fieldFocused ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .onChange(of: isFocused) { _, newValue in
            fieldFocused = newValue
        }
        .onChange(of: fieldFocused) { _, newValue in
            isFocused = newValue
        }
    }
}

// MARK: - Navigation-Aware Main View

struct KeyboardNavigableMainView: View {
    @StateObject private var navigationManager = KeyboardNavigationManager.shared
    @State private var selectedTab: Tab = .methodology
    @State private var searchText = ""
    @State private var showGlossaryPanel = false
    
    var body: some View {
        NavigationSplitView {
            EnhancedSidebarView(
                selectedTab: $selectedTab,
                searchText: $searchText,
                isSearchFocused: $navigationManager.isSearchFocused
            )
        } detail: {
            ZStack {
                TabContentView(tab: selectedTab, selectedTab: $selectedTab)
                
                // Glossary slide-over panel
                if showGlossaryPanel {
                    GlossarySlidePanel(isPresented: $showGlossaryPanel)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .onChange(of: navigationManager.currentSectionIndex) { _, newIndex in
            let tabs = Tab.allCases
            if newIndex < tabs.count {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tabs[newIndex]
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if let index = Tab.allCases.firstIndex(of: newTab) {
                navigationManager.currentSectionIndex = index
            }
        }
        .onChange(of: navigationManager.isGlossaryOpen) { _, isOpen in
            withAnimation(.spring(response: 0.3)) {
                showGlossaryPanel = isOpen
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let tab = notification.object as? Tab {
                selectedTab = tab
            }
        }
        .sheet(isPresented: $navigationManager.showKeyboardShortcuts) {
            KeyboardShortcutsView(isPresented: $navigationManager.showKeyboardShortcuts)
        }
        .onAppear {
            setupKeyboardMonitor()
        }
    }
    
    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Handle escape key
            if event.keyCode == 53 { // Escape
                if navigationManager.isSearchFocused {
                    navigationManager.isSearchFocused = false
                    return nil
                }
                if showGlossaryPanel {
                    withAnimation {
                        showGlossaryPanel = false
                        navigationManager.isGlossaryOpen = false
                    }
                    return nil
                }
            }
            
            // Handle arrow keys without modifiers for scrolling within content
            // (let system handle these)
            
            return event
        }
    }
}

// MARK: - Enhanced Sidebar with Search Focus

struct EnhancedSidebarView: View {
    @Binding var selectedTab: Tab
    @Binding var searchText: String
    @Binding var isSearchFocused: Bool
    
    @State private var expandedSections: Set<SectionCategory> = [.theoretical]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            Divider()
            
            // Search
            FocusableSearchField(
                text: $searchText,
                isFocused: $isSearchFocused,
                placeholder: "Search topics... (⌘F)"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Navigation items
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredSections) { section in
                        NavigationSection(
                            section: section,
                            selection: $selectedTab,
                            isExpanded: expandedSections.contains(section.category)
                        ) {
                            toggleSection(section.category)
                        }
                    }
                }
                .padding(12)
            }
            
            Divider()
            
            // Footer with keyboard hint
            HStack {
                Text("⌘/ for shortcuts")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("⌘↑↓ navigate")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .frame(minWidth: 250, idealWidth: 280)
    }
    
    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.apgiPrimary, .apgiSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("APGI")
                    .font(.title2.bold())
                
                Text("Framework Appendix")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    private var allSections: [SidebarSection] {
        SectionCategory.allCases.map { category in
            SidebarSection(
                category: category,
                title: category.rawValue,
                icon: category.icon,
                color: category.color,
                tabs: Tab.allCases.filter { $0.category == category }
            )
        }
    }
    
    private var filteredSections: [SidebarSection] {
        guard !searchText.isEmpty else { return allSections }
        
        return allSections.compactMap { section in
            let matchingTabs = section.tabs.filter { tab in
                tab.shortTitle.localizedCaseInsensitiveContains(searchText) ||
                tab.rawValue.localizedCaseInsensitiveContains(searchText)
            }
            
            if section.title.localizedCaseInsensitiveContains(searchText) {
                return section
            } else if !matchingTabs.isEmpty {
                return SidebarSection(
                    category: section.category,
                    title: section.title,
                    icon: section.icon,
                    color: section.color,
                    tabs: matchingTabs
                )
            }
            return nil
        }
    }
    
    private func toggleSection(_ category: SectionCategory) {
        if expandedSections.contains(category) {
            expandedSections.remove(category)
        } else {
            expandedSections.insert(category)
        }
    }
}

// MARK: - Glossary Slide Panel

struct GlossarySlidePanel: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    private var filteredEntries: [GlossaryEntry] {
        guard !searchText.isEmpty else { return GlossaryData.entries }
        return GlossaryData.entries.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Glossary")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(.bar)
            
            // Search
            TextField("Search glossary...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            // Terms list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredEntries) { entry in
                        GlossaryTermRow(entry: entry)
                    }
                }
                .padding()
            }
        }
        .frame(width: 350)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .background(Color.black.opacity(0.2).ignoresSafeArea())
        .onTapGesture {
            withAnimation {
                isPresented = false
            }
        }
    }
}

struct GlossaryTermRow: View {
    let entry: GlossaryEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(entry.term)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(entry.definition)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {} // Prevent background tap from dismissing
    }
}

// MARK: - Preview

#Preview {
    KeyboardShortcutsView(isPresented: .constant(true))
}
