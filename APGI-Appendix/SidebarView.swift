import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    @State private var searchText = ""
    @State private var expandedSections: Set<NavigationSection> = [.foundations]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: APGISpacing.sm) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.apgiPrimary, .apgiSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("APGI")
                            .font(APGITypography.titleLarge)
                            .fontWeight(.bold)

                        Text("Consciousness Framework")
                            .font(APGITypography.labelSmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(APGISpacing.lg)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search topics...", text: self.$searchText)
                        .textFieldStyle(.plain)
                }
                .padding(APGISpacing.sm)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: APGIRadius.sm))
                .padding(.horizontal, APGISpacing.lg)
            }
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: APGISpacing.xs) {
                    ForEach(self.filteredSections) { (section: SidebarSection) in
                        NavigationSectionView(
                            section: section,
                            selection: self.$selectedTab,
                            isExpanded: self.isExpanded(for: section.section)
                        ) {
                            self.toggleSection(section.section)
                        }
                    }
                }
                .padding(APGISpacing.md)
            }

            Divider()

            HStack(spacing: APGISpacing.md) {
                Button(action: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }) {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    NSApp.sendAction(#selector(NSApplication.showHelp(_:)), to: nil, from: nil)
                }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }
            .font(APGITypography.labelMedium)
            .foregroundStyle(.secondary)
            .padding(APGISpacing.lg)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 240, idealWidth: 280)
        .background(Color.surfacePrimary)
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
        let query = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return self.allSections
        }

        return self.allSections.compactMap { section in
            let sectionMatches = section.title.localizedCaseInsensitiveContains(query)

            let matchingTabs = section.tabs.filter { tab in
                tab.shortTitle.localizedCaseInsensitiveContains(query) ||
                    tab.rawValue.localizedCaseInsensitiveContains(query) ||
                    tab.searchIndexText.localizedCaseInsensitiveContains(query)
            }

            if sectionMatches {
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
            else {
                return nil
            }
        }
    }

    private func isExpanded(for section: NavigationSection) -> Bool {
        if self.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return self.expandedSections.contains(section)
        }
        else {
            return true
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

struct SidebarSection: Identifiable {
    let section: NavigationSection
    let title: String
    let icon: String
    let color: Color
    let tabs: [Tab]

    var id: NavigationSection {
        self.section
    }
}

struct NavigationSectionView: View {
    let section: SidebarSection
    @Binding var selection: Tab
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: APGISpacing.xs) {
            Button {
                self.onToggle()
            } label: {
                HStack {
                    Image(systemName: self.section.icon)
                        .font(.body)
                        .foregroundStyle(self.section.color)
                        .frame(width: 24)

                    Text(self.section.title)
                        .font(APGITypography.labelLarge)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(self.isExpanded ? 90 : 0))
                }
                .padding(.vertical, APGISpacing.sm)
                .padding(.horizontal, APGISpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: APGIRadius.sm)
                        .fill(.quaternary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)

            if self.isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(self.section.tabs, id: \.self) { tab in
                        NavigationItemRow(
                            item: tab,
                            isSelected: self.selection == tab
                        ) {
                            self.selection = tab
                        }
                    }
                }
                .padding(.leading, APGISpacing.xl)
            }
        }
    }
}

struct NavigationItemRow: View {
    let item: Tab
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            self.onSelect()
        } label: {
            HStack(spacing: APGISpacing.sm) {
                Circle()
                    .fill(self.isSelected ? self.item.category.color : .secondary.opacity(0.3))
                    .frame(width: 6, height: 6)

                Text(self.item.shortTitle)
                    .font(APGITypography.bodyMedium)
                    .foregroundStyle(self.isSelected ? .primary : .secondary)

                Spacer()

                if self.item.hasTables {
                    Circle()
                        .fill(Color.apgiAccent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, APGISpacing.sm)
            .padding(.horizontal, APGISpacing.md)
            .background {
                RoundedRectangle(cornerRadius: APGIRadius.sm)
                    .fill(
                        self.isSelected
                            ? self.item.category.color.opacity(0.15)
                            : (self.isHovered ? Color.secondary.opacity(0.3) : Color.clear)
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}
