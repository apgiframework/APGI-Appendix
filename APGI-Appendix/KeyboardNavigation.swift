import AppKit
import Combine
import SwiftUI

// MARK: - Keyboard Navigation Manager

@MainActor
final class KeyboardNavigationManager: ObservableObject {
    static let shared = KeyboardNavigationManager()

    @Published var isSearchFocused = false
    @Published var isGlossaryOpen = false
    @Published var currentSectionIndex = 0
    @Published var showKeyboardShortcuts = false

    private init() {
    }

    var allTabs: [Tab] {
        Tab.allCases
    }

    func navigateToNextSection() {
        let maxIndex = self.allTabs.count - 1
        if self.currentSectionIndex < maxIndex {
            self.currentSectionIndex += 1
        }
    }

    func navigateToPreviousSection() {
        if self.currentSectionIndex > 0 {
            self.currentSectionIndex -= 1
        }
    }

    func navigateToSection(at index: Int) {
        guard index >= 0, index < self.allTabs.count else { return }
        self.currentSectionIndex = index
    }

    func currentTab() -> Tab {
        guard self.currentSectionIndex < self.allTabs.count else { return .methodology }
        return self.allTabs[self.currentSectionIndex]
    }

    func focusSearch() {
        self.isSearchFocused = true
    }

    func toggleGlossary() {
        self.isGlossaryOpen.toggle()
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
            ("⌘G", "Toggle glossary"),
            ("⌘B", "Toggle bookmarks"),
            ("⌘S", "Toggle sidebar"),
            ("⌘/", "Show keyboard shortcuts"),
        ]),
        ("Windows", [
            ("⌘⇧T", "Open timeline window"),
            ("⌘W", "Close current window"),
            ("⌘M", "Minimize window"),
            ("⌘⌃F", "Toggle fullscreen"),
        ]),
        ("Reading", [
            ("⌘=", "Increase font size"),
            ("⌘-", "Decrease font size"),
            ("⌘0", "Reset font size"),
            ("Space", "Scroll down"),
            ("⇧Space", "Scroll up"),
        ]),
        ("General", [
            ("⌘,", "Open settings"),
            ("⌘/", "Show this help"),
            ("⌘Q", "Quit application"),
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: SFSymbols.keyboard)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Keyboard shortcuts")

                Text("Keyboard Shortcuts")
                    .font(.title2.bold())

                Spacer()

                Button {
                    self.isPresented = false
                } label: {
                    Image(systemName: SFSymbols.closeCircleFill)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close")
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
                    GridItem(.flexible(), spacing: 20),
                ], spacing: 24) {
                    ForEach(self.shortcuts, id: \.category) { section in
                        self.shortcutSection(section.category, items: section.items)
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
            Image(systemName: SFSymbols.search)
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
                .accessibilityLabel("Search")

            TextField(self.placeholder, text: self.$text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused(self.$fieldFocused)

            if !self.text.isEmpty {
                Button {
                    self.text = ""
                } label: {
                    Image(systemName: SFSymbols.closeCircleFill)
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                        .accessibilityLabel("Clear search")
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
                    self.fieldFocused ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .onChange(of: self.isFocused) { _, newValue in
            self.fieldFocused = newValue
        }
        .onChange(of: self.fieldFocused) { _, newValue in
            self.isFocused = newValue
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
                selectedTab: self.$selectedTab,
                searchText: self.$searchText,
                isSearchFocused: self.$navigationManager.isSearchFocused
            )
        } detail: {
            ZStack {
                TabContentView(tab: self.selectedTab, selectedTab: self.$selectedTab)

                // Glossary slide-over panel
                if self.showGlossaryPanel {
                    GlossarySlidePanel(isPresented: self.$showGlossaryPanel)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .onChange(of: self.navigationManager.currentSectionIndex) { _, newIndex in
            let tabs = Tab.allCases
            if newIndex < tabs.count {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.selectedTab = tabs[newIndex]
                }
            }
        }
        .onChange(of: self.selectedTab) { _, newTab in
            if let index = Tab.allCases.firstIndex(of: newTab) {
                self.navigationManager.currentSectionIndex = index
            }
        }
        .onChange(of: self.navigationManager.isGlossaryOpen) { _, isOpen in
            withAnimation(.spring(response: 0.3)) {
                self.showGlossaryPanel = isOpen
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
            if let tab = notification.object as? Tab {
                self.selectedTab = tab
            }
        }
        .sheet(isPresented: self.$navigationManager.showKeyboardShortcuts) {
            KeyboardShortcutsView(isPresented: self.$navigationManager.showKeyboardShortcuts)
        }
        .onAppear {
            self.setupKeyboardMonitor()
        }
    }

    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Handle escape key
            if event.keyCode == 53 { // Escape
                if self.navigationManager.isSearchFocused {
                    self.navigationManager.isSearchFocused = false
                    return nil
                }
                if self.showGlossaryPanel {
                    withAnimation {
                        self.showGlossaryPanel = false
                        self.navigationManager.isGlossaryOpen = false
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

    @State private var expandedSections: Set<NavigationSection> = [.foundations]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            self.sidebarHeader

            Divider()

            // Search
            FocusableSearchField(
                text: self.$searchText,
                isFocused: self.$isSearchFocused,
                placeholder: "Search topics... (⌘F)"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Navigation items
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(self.filteredSections) { (section: SidebarSection) in
                        NavigationSectionView(
                            section: section,
                            selection: self.$selectedTab,
                            isExpanded: self.expandedSections.contains(section.section)
                        ) {
                            self.toggleSection(section.section)
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
            Image(systemName: SFSymbols.methodology)
                .font(.title)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.apgiPrimary, .apgiSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityLabel("APGI Framework")

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
        NavigationSection.allCases.map { section in
            SidebarSection(
                section: section,
                title: section.rawValue,
                icon: section.icon,
                color: section.color,
                tabs: section.tabs
            )
        }
    }

    private var filteredSections: [SidebarSection] {
        guard !self.searchText.isEmpty else { return self.allSections }

        return self.allSections.compactMap { section in
            let matchingTabs = section.tabs.filter { tab in
                tab.shortTitle.localizedCaseInsensitiveContains(self.searchText) ||
                    tab.rawValue.localizedCaseInsensitiveContains(self.searchText)
            }

            if section.title.localizedCaseInsensitiveContains(self.searchText) {
                return section
            }
            else if !matchingTabs.isEmpty {
                return SidebarSection(
                    section: section.section,
                    title: section.title,
                    icon: section.icon,
                    color: section.color,
                    tabs: matchingTabs
                )
            }
            return nil
        }
    }

    private func toggleSection(_ section: NavigationSection) {
        if self.expandedSections.contains(section) {
            self.expandedSections.remove(section)
        }
        else {
            self.expandedSections.insert(section)
        }
    }
}

// MARK: - Glossary Slide Panel

struct GlossarySlidePanel: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""

    private var filteredEntries: [GlossaryEntry] {
        guard !self.searchText.isEmpty else { return GlossaryData.entries }
        return GlossaryData.entries.filter {
            $0.term.localizedCaseInsensitiveContains(self.searchText) ||
                $0.definition.localizedCaseInsensitiveContains(self.searchText)
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
                        self.isPresented = false
                    }
                } label: {
                    Image(systemName: SFSymbols.closeCircleFill)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Close glossary")
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(.bar)

            // Search
            TextField("Search glossary...", text: self.$searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Terms list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(self.filteredEntries) { entry in
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
                self.isPresented = false
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
                    self.isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(self.entry.term)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: self.isExpanded ? SFSymbols.Navigation.up.symbol : SFSymbols.Navigation.down.symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(self.isExpanded ? "Collapse" : "Expand")
                }
            }
            .buttonStyle(.plain)

            if self.isExpanded {
                Text(self.entry.definition)
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
        .onTapGesture {
        } // Prevent background tap from dismissing
    }
}

// MARK: - Preview

#Preview {
    KeyboardShortcutsView(isPresented: .constant(true))
}
