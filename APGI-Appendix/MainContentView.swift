import AppKit
import Combine
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct MainContentView: View {
  typealias ContentCategory = SectionCategory
  typealias ContentSection = Tab

  @State private var selectedCategory: ContentCategory? = Tab.methodology.category
  @State private var selectedSection: ContentSection? = .methodology
  @State private var selectedTab: Tab = .methodology
  @State private var showInspector = true
  @State private var columnVisibility = NavigationSplitViewVisibility.all
  @State private var searchPresented: Bool = false
  @AppStorage("contentFontSize") private var fontSize: Double = 15.0
  @EnvironmentObject private var bookmarkManager: BookmarkManager
  @EnvironmentObject private var navigationManager: KeyboardNavigationManager
  @EnvironmentObject private var themeManager: ThemeManager
  @State private var showUpdateCheck = false
  @State private var showKeyboardShortcuts = false

  @FocusState private var sidebarFocused: Bool
  @FocusState private var detailFocused: Bool

  var body: some View {
    let navSplitView = NavigationSplitView(columnVisibility: $columnVisibility) {
      self.sidebarView
    } detail: {
      self.detailView
    }

    let configuredView =
      navSplitView
      .frame(minWidth: 1000, minHeight: 700)
      .environmentObject(self.bookmarkManager)
      .onAppear {
        self.sidebarFocused = true
        // Sync initial sidebar visibility from settings
        self.columnVisibility = self.themeManager.sidebarVisible ? .all : .detailOnly
      }
      .onChange(of: self.themeManager.sidebarVisible) { _, newValue in
        self.columnVisibility = newValue ? .all : .detailOnly
      }
      .onChange(of: self.columnVisibility) { _, newValue in
        // Sync back to settings if user manually toggles sidebar (e.g. via system shortcut)
        self.themeManager.sidebarVisible = (newValue != .detailOnly)
      }

    let withCategoryChanges =
      configuredView
      .onChange(of: self.selectedSection) { _, newValue in
        guard let newValue = newValue else { return }
        // Update category when section changes
        self.selectedCategory = newValue.category
        // Update Handoff activity when section changes
        self.updateUserActivity()
      }

    let withNavigation =
      withCategoryChanges
      .onReceive(NotificationCenter.default.publisher(for: .navigateNext)) { _ in
        self.navigateToNext()
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigatePrevious)) { _ in
        self.navigateToPrevious()
      }
      .onReceive(NotificationCenter.default.publisher(for: .toggleInspector)) { _ in
        self.showInspector.toggle()
      }
      .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
        self.themeManager.sidebarVisible.toggle()
      }

    let withZoom =
      withNavigation
      .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
        self.fontSize = min(24, self.fontSize + 2)
      }
      .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
        self.fontSize = max(10, self.fontSize - 2)
      }
      .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
        self.fontSize = 15.0
      }

    let withSearch =
      withZoom
      .onReceive(NotificationCenter.default.publisher(for: .focusSearch)) { _ in
        self.searchPresented = true
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToSection)) { notification in
        if let section = notification.object as? String {
          self.navigateToSection(section)
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
        if let tab = notification.object as? Tab {
          self.selectedSection = tab
          self.selectedCategory = tab.category
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HandleDeepLink"))) { notification in
        if let url = notification.object as? URL {
          self.handleDeepLink(url)
        }
      }

    let withExport =
      withSearch
      .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "APGI-Framework-Section.pdf"
        panel.begin { response in
          if response == .OK, let url = panel.url {
            self.exportCurrentViewToPDF(url: url)
          }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .exportCurrentSection)) { _ in
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").txt"
        panel.begin { response in
          if response == .OK, let url = panel.url {
            do {
              try (self.selectedSection?.fullContent ?? "").write(
                to: url, atomically: true, encoding: .utf8)
            } catch {
              logError(
                error, context: "MainContentView.exportCurrentSection", function: #function,
                file: #file, line: #line)
            }
            do {
              let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
              let fileSize = UInt64(resourceValues.fileSize ?? 0)
              logInfo(
                "Exported file size: \(fileSize) bytes",
                context: "MainContentView.exportCurrentSection")
            } catch {
              logError(
                error, context: "MainContentView.exportCurrentSection", function: #function,
                file: #file, line: #line)
            }
          }
        }
      }

    return
      (withExport
      .onReceive(NotificationCenter.default.publisher(for: .openHelpGuide)) { _ in
        self.showHelpGuide()
      }
      .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
        self.checkForUpdates()
      }
      .onReceive(NotificationCenter.default.publisher(for: .printCurrentSection)) { _ in
        self.printCurrentSection()
      }
      .onReceive(NotificationCenter.default.publisher(for: .copyCitation)) { _ in
        self.copyCitationForCurrentSection()
      }
      .onReceive(NotificationCenter.default.publisher(for: .scrollToTables)) { notification in
        if let tab = notification.object as? Tab {
          self.selectedSection = tab
          self.selectedCategory = tab.category
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(for: NSNotification.Name("HandleHandoffActivity"))
      ) { notification in
        if let userActivity = notification.object as? NSUserActivity {
          self.handleIncomingHandoff(userActivity)
        }
      })
      .sheet(isPresented: self.$showUpdateCheck) {
        UpdateCheckView()
      }
      .overlay {
        if self.showKeyboardShortcuts {
          KeyboardShortcutsView(isPresented: self.$showKeyboardShortcuts)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3).ignoresSafeArea())
        }
      }
  }

  private var sidebarView: some View {
    SidebarView(
      selectedTab: Binding(
        get: { self.selectedSection ?? .methodology },
        set: { self.selectedSection = $0 }
      )
    )
    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 350)
    .focusable()
    .focused(self.$sidebarFocused)
    .onKeyPress(.tab) {
      self.detailFocused = true
      self.sidebarFocused = false
      return .handled
    }
  }

  private var detailView: some View {
    ZStack {
      Color.spaceBlack.ignoresSafeArea()

      if let section = selectedSection {
        TabContentView(tab: section, selectedTab: $selectedTab)
          .id(section.id)
          .transition(.opacity.combined(with: .move(edge: .trailing)))
      } else {
        VStack(spacing: 20) {
          Image(systemName: "book.closed")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
          Text("Select a topic to begin")
            .font(.title2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
          APGIEquationView(fontSize: 18)
      }

      ToolbarItemGroup {
        NetworkStatusView()

        if let section = selectedSection {
          BookmarkButton(tab: section)
        }

        Button {
          self.themeManager.focusModeEnabled.toggle()
        } label: {
          Image(systemName: SFSymbols.focus)
        }
        .apgiAccessibility(
          label: "Focus mode",
          hint: self.themeManager.focusModeEnabled ? "Exit focus mode" : "Enter focus mode",
          traits: .isButton
        )

        Button {
          self.searchPresented.toggle()
        } label: {
          Image(systemName: SFSymbols.search)
        }
        .keyboardShortcut("f", modifiers: [.command])
        .apgiAccessibility(
          label: "Search",
          hint: "Search all content",
          traits: .isButton
        )

        if self.selectedSection != nil {
          Menu {
            Button("Export as PDF...") {
              self.exportToPDF()
            }
            Button("Export as Text...") {
              self.exportToText()
            }
          } label: {
            Image(systemName: SFSymbols.share)
          }
          .apgiAccessibility(
            label: "Export",
            hint: "Export current section",
            traits: .isButton
          )
        }

        FontSizeControl()
      }

      ToolbarItem(placement: .automatic) {
        Button {
          self.showInspector.toggle()
        } label: {
          Label("Toggle Inspector", systemImage: SFSymbols.sidebarRight)
        }
      }
    }
  }

  @ViewBuilder
  private var detailContentView: some View {
    if let section = selectedSection {
      HStack(spacing: 0) {
        DetailContentView(section: section, focusModeEnabled: self.$themeManager.focusModeEnabled)
          .environmentObject(self.bookmarkManager)

        if self.showInspector {
          InspectorView(section: section)
            .frame(width: 280)
            .background(.bar)
        }
      }
    } else {
      WelcomeView()
    }
  }

  @ViewBuilder
  private var focusModeOverlay: some View {
    // Focus mode is handled in detailContentView, not here to prevent double overlay
  }

  @ViewBuilder
  private var searchOverlay: some View {
    if self.searchPresented {
      SearchView(isPresented: self.$searchPresented) { tab in
        self.selectedCategory = tab.category
        self.selectedSection = tab
        self.setupHandoff()
      }
    }
  }

  @State var userActivity: NSUserActivity?

  // MARK: - Handoff Support

  func setupHandoff() {
    // Create user activity for current content
    self.updateUserActivity()
  }

  func updateUserActivity() {
    // End any existing activity
    self.userActivity?.invalidate()

    guard let section = selectedSection else {
      self.userActivity = nil
      return
    }

    // Create new activity for current section
    let activity = NSUserActivity(activityType: "com.apgi.appendix.content")
    activity.title = "Reading: \(section.shortTitle)"
    activity.userInfo = [
      "section": section.rawValue,
      "category": section.category.rawValue
    ]
    activity.isEligibleForHandoff = true
    activity.isEligibleForSearch = true
    activity.isEligibleForPublicIndexing = false

    // webpageURL only accepts http/https schemes, not custom schemes
    // The deep link functionality is handled through userInfo, not webpageURL
    // Do NOT set webpageURL to custom scheme URLs - it causes a runtime crash

    activity.becomeCurrent()
    self.userActivity = activity

    logInfo(
      "Updated Handoff activity for section: \(section.rawValue)",
      context: "MainContentView.updateUserActivity")
  }

  func createDeepLinkURL(for section: Tab) -> URL? {
    return DeepLinkManager.shared.createURL(for: section)
  }

  func handleIncomingHandoff(_ userActivity: NSUserActivity) {
    guard userActivity.activityType == "com.apgi.appendix.content",
      let userInfo = userActivity.userInfo,
      let sectionName = userInfo["section"] as? String
    else {
      return
    }

    // Navigate to the handed-off section
    self.navigateToSection(sectionName)
    logInfo(
      "Handled incoming Handoff for section: \(sectionName)",
      context: "MainContentView.handleIncomingHandoff")
  }

  func handleDeepLink(_ url: URL) {
    if let tab = DeepLinkManager.shared.parseTab(from: url) {
      self.selectedSection = tab
      self.selectedCategory = tab.category
    }
  }

  // MARK: - Navigation Methods

  private func navigateToNext() {
    guard let currentCategory = selectedCategory,
      let currentSection = selectedSection
    else { return }

    let sections = currentCategory.sections
    if let currentIndex = sections.firstIndex(of: currentSection) {
      if currentIndex < sections.count - 1 {
        // Next section in current category
        self.selectedSection = sections[currentIndex + 1]
      } else {
        // Move to next category
        let allCategories = SectionCategory.allCases
        if let categoryIndex = allCategories.firstIndex(of: currentCategory),
          categoryIndex < allCategories.count - 1 {
          let nextCategory = allCategories[categoryIndex + 1]
          self.selectedCategory = nextCategory
          self.selectedSection = nextCategory.sections.first
        }
      }
    }
  }

  private func navigateToPrevious() {
    guard let currentCategory = selectedCategory,
      let currentSection = selectedSection
    else { return }

    let sections = currentCategory.sections
    if let currentIndex = sections.firstIndex(of: currentSection) {
      if currentIndex > 0 {
        // Previous section in current category
        self.selectedSection = sections[currentIndex - 1]
      } else {
        // Move to previous category
        let allCategories = SectionCategory.allCases
        if let categoryIndex = allCategories.firstIndex(of: currentCategory),
          categoryIndex > 0 {
          let prevCategory = allCategories[categoryIndex - 1]
          self.selectedCategory = prevCategory
          self.selectedSection = prevCategory.sections.last
        }
      }
    }
  }

  private func navigateToSection(_ sectionName: String) {
    if let tab = Tab.allCases.first(where: { $0.rawValue.lowercased() == sectionName.lowercased() }) {
      self.selectedCategory = tab.category
      self.selectedSection = tab
    }
  }

  // MARK: - Export Methods

  private func exportCurrentViewToPDF(url: URL) {
    guard let selectedSection = selectedSection else {
      self.showExportError(message: "No section selected for export")
      return
    }

    Task { @MainActor in
      // Create the content view for the selected section
      let contentView = selectedSection.view
      let hostingView = NSHostingView(rootView: contentView)

      // Set up the hosting view with proper sizing
      hostingView.frame = NSRect(x: 0, y: 0, width: 792, height: 612)  // Standard US Letter size
      hostingView.layoutSubtreeIfNeeded()

      // Create PDF data
      let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)

      do {
        try pdfData.write(to: url)
        self.showExportSuccess(message: "PDF exported successfully to \(url.lastPathComponent)")
      } catch {
        logError(
          error, context: "ContentCacheManager", function: #function, file: #file, line: #line)
      }
    }
  }

  private func showExportSuccess(message: String) {
    let alert = NSAlert()
    alert.messageText = "Export Successful"
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private func showExportError(message: String) {
    let alert = NSAlert()
    alert.messageText = "Export Failed"
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private func exportToPDF() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").pdf"
    panel.begin { response in
      if response == .OK, let url = panel.url {
        self.exportCurrentViewToPDF(url: url)
      }
    }
  }

  private func exportToText() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.plainText]
    panel.nameFieldStringValue = "\(self.selectedSection?.rawValue ?? "section").txt"
    panel.begin { response in
      if response == .OK, let url = panel.url {
        do {
          try (self.selectedSection?.fullContent ?? "").write(
            to: url, atomically: true, encoding: .utf8)
        } catch {
          logError(
            error, context: "MainContentView.exportToText", function: #function, file: #file,
            line: #line)
        }
      }
    }
  }

  private func copyCitationForCurrentSection() {
    guard let selectedSection else { return }
    ClipboardManager.shared.copyCitation(
      title: selectedSection.shortTitle,
      year: String(Calendar.current.component(.year, from: Date())),
      source: "APGI Appendix"
    )
  }

  private func toggleBookmark() {
    guard let selectedSection = selectedSection else { return }
    if self.bookmarkManager.isBookmarked(selectedSection) {
      self.bookmarkManager.removeBookmark(selectedSection)
    } else {
      self.bookmarkManager.addBookmark(selectedSection)
    }
  }

  // MARK: - Help and Updates

  private func showHelpGuide() {
    URLValidator.shared.openSafely("https://apgiframework.com") {
      // Fallback: show local help content
      self.showLocalHelp()
    }
  }

  private func showLocalHelp() {
    let helpContent = URLValidator.shared.getLocalHelpContent()
    WindowManager.shared.showHelpWindow(content: helpContent)
  }

  private func checkForUpdates() {
    self.showUpdateCheck = true
  }

  private func printCurrentSection() {
    guard let selectedSection = selectedSection else {
      self.showExportError(message: "No section selected for printing")
      return
    }

    Task { @MainActor in
      // Create the content view for the selected section
      let contentView = selectedSection.view
      let hostingView = NSHostingView(rootView: contentView)

      // Set up the hosting view with proper sizing
      hostingView.frame = NSRect(x: 0, y: 0, width: 792, height: 612)  // Standard US Letter size
      hostingView.layoutSubtreeIfNeeded()

      // Create print operation
      let printOperation = NSPrintOperation(view: hostingView)
      printOperation.printInfo.orientation = .portrait
      printOperation.printInfo.scalingFactor = 1.0

      // Set print job title
      printOperation.printInfo.jobDisposition = .spool

      // Run the print operation
      printOperation.run()
    }
  }

  private struct DetailContentView: View {
    let section: Tab
    @Binding var focusModeEnabled: Bool

    var body: some View {
      ZStack {
        TabContentView(tab: self.section, selectedTab: .constant(self.section))

        if self.focusModeEnabled {
          FocusModeView(
            isEnabled: self.$focusModeEnabled,
            content: self.section.fullContent,
            title: self.section.rawValue
          )
        }
      }
    }
  }

  private struct InspectorView: View {
    let section: Tab

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text("Inspector")
          .font(.headline)

        VStack(alignment: .leading, spacing: 6) {
          Text(self.section.shortTitle)
            .font(.subheadline.weight(.semibold))

          Text(self.section.category.rawValue)
            .font(.footnote)
            .foregroundStyle(.secondary)

          // Content type indicators
          HStack(spacing: 8) {
            if self.section.hasTables {
              Label("Tables", systemImage: "tablecells")
                .font(.caption)
                .foregroundStyle(.blue)
            }

            if self.section.hasMath {
              Label("Math", systemImage: "function")
                .font(.caption)
                .foregroundStyle(.orange)
            }

            if self.section.hasDiagrams {
              Label("Diagrams", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption)
                .foregroundStyle(.green)
            }
          }

          // Related sections (cross-references)
          if !self.section.relatedSections.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("Related")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

              ForEach(self.section.relatedSections, id: \.self) { relatedSection in
                HStack(spacing: 4) {
                  Image(systemName: relatedSection.icon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                  Text(relatedSection.shortTitle)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
              }
            }
          }

          // Additional metadata
          Divider()

          VStack(alignment: .leading, spacing: 4) {
            Text("Last Updated")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
            Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
        }

        Spacer()
      }
      .padding()
    }
  }

  private struct WelcomeView: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text("APGI Appendix")
          .font(.largeTitle.weight(.bold))
        Text("Select a category and section to begin.")
          .foregroundStyle(.secondary)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }
}
