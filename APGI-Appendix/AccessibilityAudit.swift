import Accessibility
import SwiftUI

// MARK: - Accessibility Audit Results

struct AccessibilityAuditResult {
  let viewName: String
  let issues: [AccessibilityIssue]
  let recommendations: [String]
}

struct AccessibilityIssue {
  let severity: AccessibilitySeverity
  let description: String
  let location: String
}

enum AccessibilitySeverity {
  case critical
  case high
  case medium
  case low

  var color: Color {
    switch self {
    case .critical: return .red
    case .high: return .orange
    case .medium: return .yellow
    case .low: return .green
    }
  }
}

// MARK: - Accessibility Auditor

class AccessibilityAuditor {
  static let shared = AccessibilityAuditor()

  private init() {
  }

  func performAudit() -> [AccessibilityAuditResult] {
    var results: [AccessibilityAuditResult] = []

    // Audit Main Navigation
    results.append(self.auditMainNavigation())

    // Audit Content Views
    results.append(self.auditContentViews())

    // Audit Interactive Elements
    results.append(self.auditInteractiveElements())

    // Audit Settings
    results.append(self.auditSettings())

    // Audit Tables and Data
    results.append(self.auditDataTables())

    return results
  }

  private func auditMainNavigation() -> AccessibilityAuditResult {
    let issues = [
      AccessibilityIssue(
        severity: .medium,
        description: "Sidebar navigation may not be properly announced to VoiceOver",
        location: "MainContentView.swift"
      ),
      AccessibilityIssue(
        severity: .low,
        description: "Keyboard navigation could be improved with better focus management",
        location: "SidebarView.swift"
      )
    ]

    let recommendations = [
      "Add accessibility labels to all navigation items",
      "Implement proper focus management for keyboard navigation",
      "Add accessibility hints for complex navigation patterns",
      "Ensure all interactive elements have sufficient touch targets (44x44 points minimum)"
    ]

    return AccessibilityAuditResult(
      viewName: "Main Navigation",
      issues: issues,
      recommendations: recommendations
    )
  }

  private func auditContentViews() -> AccessibilityAuditResult {
    let issues = [
      AccessibilityIssue(
        severity: .high,
        description: "Long text content may not be properly structured for screen readers",
        location: "MethodologyView.swift, MathematicalModelView.swift"
      ),
      AccessibilityIssue(
        severity: .medium,
        description: "Images and diagrams may lack alternative text",
        location: "Various content views"
      )
    ]

    let recommendations = [
      "Add proper heading structure using semantic HTML-like elements",
      "Provide alternative text for all images and diagrams",
      "Implement text resizing support for Dynamic Type",
      "Add accessibility labels for mathematical equations",
      "Ensure proper reading order for complex layouts"
    ]

    return AccessibilityAuditResult(
      viewName: "Content Views",
      issues: issues,
      recommendations: recommendations
    )
  }

  private func auditInteractiveElements() -> AccessibilityAuditResult {
    let issues = [
      AccessibilityIssue(
        severity: .high,
        description: "Buttons may lack proper accessibility labels",
        location: "BookmarkManager.swift, ExportManager.swift"
      ),
      AccessibilityIssue(
        severity: .medium,
        description: "Custom controls may not be accessible",
        location: "Custom SwiftUI components"
      )
    ]

    let recommendations = [
      "Add accessibility labels to all buttons and controls",
      "Implement accessibility actions for custom gestures",
      "Provide accessibility values for sliders and progress indicators",
      "Ensure all interactive elements are keyboard accessible",
      "Add accessibility hints for complex interactions"
    ]

    return AccessibilityAuditResult(
      viewName: "Interactive Elements",
      issues: issues,
      recommendations: recommendations
    )
  }

  private func auditSettings() -> AccessibilityAuditResult {
    let issues = [
      AccessibilityIssue(
        severity: .medium,
        description: "Settings toggles may not be properly announced",
        location: "SettingsView.swift"
      )
    ]

    let recommendations = [
      "Add accessibility labels for all settings options",
      "Implement accessibility values for toggle states",
      "Ensure settings are properly grouped and ordered",
      "Add accessibility hints for complex settings"
    ]

    return AccessibilityAuditResult(
      viewName: "Settings",
      issues: issues,
      recommendations: recommendations
    )
  }

  private func auditDataTables() -> AccessibilityAuditResult {
    let issues = [
      AccessibilityIssue(
        severity: .critical,
        description: "Data tables may not be accessible to screen readers",
        location: "EnhancedDataTableView.swift, LifeStagesView.swift"
      )
    ]

    let recommendations = [
      "Implement proper table headers and row/column associations",
      "Add accessibility labels for table content",
      "Ensure table navigation works with VoiceOver",
      "Provide table summaries and captions",
      "Implement sorting and filtering accessibility"
    ]

    return AccessibilityAuditResult(
      viewName: "Data Tables",
      issues: issues,
      recommendations: recommendations
    )
  }
}

// MARK: - Accessibility Improvements

extension View {
  func apgiAccessible() -> some View {
    self
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(self.accessibilityLabel))
      .accessibilityHint(Text(self.accessibilityHint))
      .accessibilityValue(Text(self.accessibilityValue))
  }

  private var accessibilityLabel: String {
    // Default implementation - should be overridden per view
    return "APGI Appendix Content"
  }

  private var accessibilityHint: String {
    // Default implementation - should be overridden per view
    return "Double tap to interact"
  }

  private var accessibilityValue: String {
    // Default implementation - should be overridden per view
    return ""
  }
}

// MARK: - Enhanced Accessibility Components

struct AccessibleButton: View {
  let title: String
  let action: () -> Void
  let hint: String?

  init(_ title: String, hint: String? = nil, action: @escaping () -> Void) {
    self.title = title
    self.hint = hint
    self.action = action
  }

  var body: some View {
    Button(action: self.action) {
      Text(self.title)
        .padding()
        .frame(minHeight: 44)  // Minimum touch target
    }
    .accessibilityLabel(self.title)
    .accessibilityHint(self.hint ?? "Double tap to \(self.title.lowercased())")
    .accessibilityAddTraits(.isButton)
  }
}

struct AccessibleToggle: View {
  let title: String
  @Binding var isOn: Bool
  let hint: String?

  init(_ title: String, isOn: Binding<Bool>, hint: String? = nil) {
    self.title = title
    self._isOn = isOn
    self.hint = hint
  }

  var body: some View {
    Toggle(self.title, isOn: self.$isOn)
      .accessibilityLabel(self.title)
      .accessibilityHint(self.hint ?? "Double tap to toggle \(self.title.lowercased())")
      .accessibilityValue(self.isOn ? "On" : "Off")
      .accessibilityAddTraits(.isButton)
  }
}

struct AccessibleSlider: View {
  let title: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let hint: String?

  init(_ title: String, value: Binding<Double>, in range: ClosedRange<Double>, hint: String? = nil) {
    self.title = title
    self._value = value
    self.range = range
    self.hint = hint
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(self.title)
        .font(.headline)

      Slider(value: self.$value, in: self.range) {
        Text(self.title)
      } minimumValueLabel: {
        Text("\(self.range.lowerBound, specifier: "%.0f")")
          .font(.caption)
      } maximumValueLabel: {
        Text("\(self.range.upperBound, specifier: "%.0f")")
          .font(.caption)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(self.title): \(Int(self.value))")
    .accessibilityHint(self.hint ?? "Swipe up or down to adjust \(self.title.lowercased())")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        self.value = min(self.value + 1, self.range.upperBound)
      case .decrement:
        self.value = max(self.value - 1, self.range.lowerBound)
      @unknown default:
        break
      }
    }
  }
}

// MARK: - Accessibility Audit View

struct AccessibilityAuditView: View {
  @State private var auditResults: [AccessibilityAuditResult] = []
  @State private var isRunningAudit = false

  var body: some View {
    NavigationView {
      List {
        auditSection
        if !auditResults.isEmpty {
          auditResultsSections
        }
      }
      .navigationTitle("Accessibility Audit")
    }
    .task {
      runAudit()
    }
  }

  private var auditSection: some View {
    Section("Accessibility Audit") {
      Button(action: runAudit) {
        HStack {
          if isRunningAudit {
            ProgressView()
              .scaleEffect(0.8)
          }
          Text(isRunningAudit ? "Running Audit..." : "Run Accessibility Audit")
        }
      }
      .disabled(isRunningAudit)
    }
  }

  private var auditResultsSections: some View {
    ForEach(Array(auditResults.indices), id: \.self) { index in
      auditResultSection(for: auditResults[index])
    }
  }

  private func auditResultSection(for result: AccessibilityAuditResult) -> some View {
    Section(result.viewName) {
      issuesView(for: result.issues)
      if !result.recommendations.isEmpty {
        recommendationsView(for: result.recommendations)
      }
    }
  }

  private func issuesView(for issues: [AccessibilityIssue]) -> some View {
    ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Circle()
            .fill(issue.severity.color)
            .frame(width: 8, height: 8)

          Text(issue.severity.description.capitalized)
            .font(.caption)
            .foregroundColor(issue.severity.color)

          Spacer()
        }

        Text(issue.description)
          .font(.body)

        Text("Location: \(issue.location)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(.vertical, 2)
    }
  }

  private func recommendationsView(for recommendations: [String]) -> some View {
    VStack(alignment: .leading) {
      Text("Recommendations:")
        .font(.headline)
        .padding(.top)

      ForEach(recommendations, id: \.self) { recommendation in
        HStack(alignment: .top, spacing: 8) {
          Text("•")
            .foregroundColor(.blue)
          Text(recommendation)
            .font(.body)
        }
        .padding(.vertical, 1)
      }
    }
  }

  private func runAudit() {
    self.isRunningAudit = true

    Task {
      let results = AccessibilityAuditor.shared.performAudit()

      await MainActor.run {
        self.auditResults = results
        self.isRunningAudit = false
      }
    }
  }
}

// MARK: - Accessibility Severity Extension

extension AccessibilitySeverity: CaseIterable, CustomStringConvertible {
  var description: String {
    switch self {
    case .critical: return "critical"
    case .high: return "high"
    case .medium: return "medium"
    case .low: return "low"
    }
  }
}
