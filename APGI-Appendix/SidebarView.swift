import AppKit
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
            .accessibilityLabel("APGI Framework logo")

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("APGI Consciousness Framework")

        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          TextField("Search topics...", text: self.$searchText)
            .textFieldStyle(.plain)
            .accessibilityLabel("Search sidebar topics")
            .accessibilityHint("Type to filter sections and topics")
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
        SettingsLink {
          Label("Settings", systemImage: "gear")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open settings window")
        .accessibilityHint("Configure application preferences")

        Spacer()

        Button(action: {
          if let url = URL(string: "https://docs.apgi-framework.org") {
            NSWorkspace.shared.open(url)
          }
        }) {
          Label("Help", systemImage: "questionmark.circle")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open help documentation")
        .accessibilityHint("View user guide and documentation")
      }
      .font(APGITypography.labelMedium)
      .foregroundStyle(.secondary)
      .padding(APGISpacing.lg)
      .background(.ultraThinMaterial)
    }
    .frame(minWidth: 240, idealWidth: 280)
    .background(Color.surfacePrimary)
    .onReceive(NotificationCenter.default.publisher(for: .toggleAllSections)) { _ in
      self.toggleAllSections()
    }
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
        tab.shortTitle.localizedCaseInsensitiveContains(query)
          || tab.rawValue.localizedCaseInsensitiveContains(query)
          || tab.searchIndexText.localizedCaseInsensitiveContains(query)
      }

      if sectionMatches {
        return section
      } else if !matchingTabs.isEmpty {
        return SidebarSection(
          section: section.section,
          title: section.title,
          icon: section.icon,
          color: section.color,
          tabs: matchingTabs
        )
      } else {
        return nil
      }
    }
  }

  private func isExpanded(for section: NavigationSection) -> Bool {
    if self.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return self.expandedSections.contains(section)
    } else {
      return true
    }
  }

  private func toggleSection(_ section: NavigationSection) {
    if self.expandedSections.contains(section) {
      self.expandedSections.remove(section)
    } else {
      self.expandedSections.insert(section)
    }
  }

  private func toggleAllSections() {
    if self.expandedSections.count == NavigationSection.allCases.count {
      self.expandedSections.removeAll()
    } else {
      self.expandedSections = Set(NavigationSection.allCases)
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
            .accessibilityHidden(true)

          Text(self.section.title)
            .font(APGITypography.labelLarge)
            .foregroundStyle(.primary)

          Spacer()

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(self.isExpanded ? 90 : 0))
            .accessibilityHidden(true)
        }
        .padding(.vertical, APGISpacing.sm)
        .padding(.horizontal, APGISpacing.md)
        .background(
          RoundedRectangle(cornerRadius: APGIRadius.sm)
            .fill(.quaternary.opacity(0.3))
        )
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(self.section.title) section")
      .accessibilityHint(self.isExpanded ? "Collapse section" : "Expand section")
      .accessibilityValue(self.isExpanded ? "Expanded" : "Collapsed")
      .contextMenu {
        Button {
          // Expand/collapse all sections
          NotificationCenter.default.post(name: .toggleAllSections, object: nil)
        } label: {
          Label(
            self.isExpanded ? "Collapse All" : "Expand All",
            systemImage: self.isExpanded ? "chevron.up" : "chevron.down")
        }

        Divider()

        Button {
          // Navigate to first item in section
          if let firstTab = self.section.tabs.first {
            self.selection = firstTab
          }
        } label: {
          Label("Go to First Item", systemImage: "arrow.right")
        }
        .disabled(self.section.tabs.isEmpty)
      }

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
      self.buttonContent
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      self.isHovered = hovering
    }
    .accessibilityLabel("\(self.item.shortTitle), \(self.item.category.rawValue) section")
    .accessibilityHint("Navigate to \(self.item.shortTitle)")
    .accessibilityValue(self.isSelected ? "Selected" : "Not selected")
    .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    .contextMenu {
      self.contextMenuContent
    }
  }

  private var buttonContent: some View {
    HStack(spacing: APGISpacing.sm) {
      Circle()
        .fill(self.isSelected ? self.item.category.color : .secondary.opacity(0.3))
        .frame(width: 6, height: 6)
        .accessibilityHidden(true)

      Text(self.item.shortTitle)
        .font(APGITypography.bodyMedium)
        .foregroundStyle(self.isSelected ? .primary : .secondary)

      Spacer()

      if self.item.hasTables {
        Circle()
          .fill(Color.apgiAccent)
          .frame(width: 8, height: 8)
          .accessibilityLabel("Contains data tables")
      }
    }
    .padding(.vertical, APGISpacing.sm)
    .padding(.horizontal, APGISpacing.md)
    .background {
      RoundedRectangle(cornerRadius: APGIRadius.sm)
        .fill(self.backgroundColor)
    }
  }

  private var backgroundColor: Color {
    if self.isSelected {
      return self.item.category.color.opacity(0.15)
    } else if self.isHovered {
      return Color.secondary.opacity(0.3)
    } else {
      return Color.clear
    }
  }

  @ViewBuilder
  private var contextMenuContent: some View {
    Button {
      self.onSelect()
    } label: {
      Label("Open \(self.item.shortTitle)", systemImage: "arrow.right")
    }

    if self.item.hasTables {
      Divider()

      Button {
        // Scroll to first table in content
        NotificationCenter.default.post(name: .scrollToTables, object: self.item)
      } label: {
        Label("Go to Tables", systemImage: "tablecells")
      }
    }

    Divider()

    Button {
      // Copy section title to clipboard
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(self.item.shortTitle, forType: .string)
    } label: {
      Label("Copy Title", systemImage: "doc.on.doc")
    }
  }
}

// ... (rest of the code remains the same)
