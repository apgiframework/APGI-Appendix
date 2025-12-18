import SwiftUI
import AppKit
import Combine

// MARK: - Onboarding Data Model

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let imageType: ImageType
    let tips: [String]
    let highlightColor: Color
    
    enum ImageType {
        case system
        case asset
        case custom
    }
}

// MARK: - Onboarding Manager

@MainActor
final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("onboardingVersion") var completedOnboardingVersion = 0
    
    @Published var isShowingOnboarding = false
    @Published var currentStep = 0
    
    private let currentOnboardingVersion = 1
    
    private init() {}
    
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding || completedOnboardingVersion < currentOnboardingVersion
    }
    
    func startOnboarding() {
        currentStep = 0
        isShowingOnboarding = true
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        completedOnboardingVersion = currentOnboardingVersion
        isShowingOnboarding = false
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        completedOnboardingVersion = 0
    }
    
    let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to APGI Appendix",
            subtitle: "Your comprehensive guide to consciousness research",
            description: "Explore the Allostatic Precision-Gated Ignition framework through interactive content, neural circuit diagrams, and detailed scientific documentation.",
            imageName: "brain.head.profile",
            imageType: .system,
            tips: [
                "Navigate through 23 topic sections",
                "Interactive timeline visualizations",
                "Comprehensive glossary with 50+ terms"
            ],
            highlightColor: .blue
        ),
        OnboardingStep(
            title: "Sidebar Navigation",
            subtitle: "Quickly access any topic",
            description: "Use the sidebar to browse through theoretical foundations, mathematical models, biological implementations, and clinical applications. Sections are organized by category for easy discovery.",
            imageName: "sidebar.leading",
            imageType: .system,
            tips: [
                "⌘1-9 jumps to sections quickly",
                "⌘↑↓ navigates between sections",
                "Search filters topics in real-time"
            ],
            highlightColor: .purple
        ),
        OnboardingStep(
            title: "Interactive Tables",
            subtitle: "Rich data presentation",
            description: "Complex scientific data is presented in sortable, interactive tables. Click column headers to sort, hover for highlights, and select rows to focus on specific information.",
            imageName: "tablecells",
            imageType: .system,
            tips: [
                "Click headers to sort columns",
                "Tables auto-detect from content",
                "Copy data with right-click"
            ],
            highlightColor: .green
        ),
        OnboardingStep(
            title: "Glossary Integration",
            subtitle: "Instant term definitions",
            description: "Scientific terms are automatically highlighted throughout the content. Click any highlighted term to see its definition in a popover, or press ⌘G to open the full glossary panel.",
            imageName: "text.book.closed",
            imageType: .system,
            tips: [
                "⌘G toggles glossary panel",
                "⌘⇧G opens glossary window",
                "50+ APGI-specific terms"
            ],
            highlightColor: .orange
        ),
        OnboardingStep(
            title: "Neural Timeline",
            subtitle: "Visualize ignition dynamics",
            description: "The interactive timeline shows the temporal sequence of neural events during conscious ignition. Play animations, scrub through time, and click events for detailed descriptions.",
            imageName: "timeline.selection",
            imageType: .system,
            tips: [
                "⌘⇧T opens timeline window",
                "Drag playhead to scrub",
                "Speed controls: 0.5x, 1x, 2x"
            ],
            highlightColor: .red
        ),
        OnboardingStep(
            title: "Theme & Accessibility",
            subtitle: "Customize your experience",
            description: "Choose between light, dark, or system-matching themes. Enable high contrast mode for improved readability. Adjust font sizes and accent colors to your preference.",
            imageName: "paintpalette",
            imageType: .system,
            tips: [
                "⌘, opens Settings",
                "High contrast improves borders",
                "Custom accent colors available"
            ],
            highlightColor: .teal
        ),
        OnboardingStep(
            title: "Keyboard Shortcuts",
            subtitle: "Power user features",
            description: "Navigate efficiently with comprehensive keyboard shortcuts. Press ⌘/ anytime to see the full list of available shortcuts for navigation, search, and window management.",
            imageName: "keyboard",
            imageType: .system,
            tips: [
                "⌘F focuses search",
                "⌘/ shows all shortcuts",
                "Esc closes panels"
            ],
            highlightColor: .indigo
        ),
        OnboardingStep(
            title: "You're Ready!",
            subtitle: "Start exploring the APGI framework",
            description: "Dive into the theoretical foundations of consciousness, explore neural implementations, and discover clinical applications. The framework integrates predictive processing with global workspace theory.",
            imageName: "checkmark.seal.fill",
            imageType: .system,
            tips: [
                "Start with 'Methodology' section",
                "Use search to find specific topics",
                "Bookmark important sections"
            ],
            highlightColor: .green
        )
    ]
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @ObservedObject private var manager = OnboardingManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var animateContent = false
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
            
            // Content area
            TabView(selection: $manager.currentStep) {
                ForEach(Array(manager.steps.enumerated()), id: \.element.id) { index, step in
                    stepView(step, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut(duration: 0.3), value: manager.currentStep)
            
            // Navigation buttons
            navigationButtons
        }
        .frame(width: 700, height: 550)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 30)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<manager.steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= manager.currentStep
                          ? manager.steps[manager.currentStep].highlightColor
                          : Color.white.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: manager.currentStep)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
    
    // MARK: - Step View
    
    private func stepView(_ step: OnboardingStep, index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(step.highlightColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(step.highlightColor.gradient)
                    .frame(width: 100, height: 100)
                
                Image(systemName: step.imageName)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, value: manager.currentStep)
            }
            .scaleEffect(animateContent ? 1 : 0.5)
            .opacity(animateContent ? 1 : 0)
            
            // Text content
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(step.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(step.highlightColor)
                
                Text(step.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            .offset(y: animateContent ? 0 : 20)
            .opacity(animateContent ? 1 : 0)
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(step.tips.enumerated()), id: \.offset) { tipIndex, tip in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(step.highlightColor)
                        
                        Text(tip)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .offset(x: animateContent ? 0 : -20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(
                        .spring(response: 0.4).delay(Double(tipIndex) * 0.1),
                        value: animateContent
                    )
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Skip button
            if manager.currentStep < manager.steps.count - 1 {
                Button("Skip") {
                    manager.completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14, weight: .medium))
            }
            
            Spacer()
            
            // Back button
            if manager.currentStep > 0 {
                Button {
                    withAnimation {
                        manager.currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Next/Get Started button
            Button {
                if manager.currentStep < manager.steps.count - 1 {
                    withAnimation {
                        manager.currentStep += 1
                        // Reset animation for new step
                        animateContent = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                animateContent = true
                            }
                        }
                    }
                } else {
                    manager.completeOnboarding()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(manager.currentStep < manager.steps.count - 1 ? "Next" : "Get Started")
                    Image(systemName: manager.currentStep < manager.steps.count - 1
                          ? "chevron.right"
                          : "arrow.right")
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(manager.steps[manager.currentStep].highlightColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.12, blue: 0.2),
                Color(red: 0.1, green: 0.1, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Onboarding Container

struct OnboardingContainer<Content: View>: View {
    @ObservedObject private var manager = OnboardingManager.shared
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
            
            if manager.isShowingOnboarding {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                OnboardingView()
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onAppear {
            if manager.shouldShowOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4)) {
                        manager.startOnboarding()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Spotlight

struct FeatureSpotlight: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isHovered ? color.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Start Panel

struct QuickStartPanel: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = OnboardingManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Start")
                        .font(.title2.bold())
                    
                    Text("Get the most out of APGI Appendix")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Feature spotlights
            VStack(spacing: 12) {
                FeatureSpotlight(
                    title: "Take the Tour",
                    description: "New here? Walk through all features step by step",
                    icon: "figure.walk",
                    color: .blue
                ) {
                    dismiss()
                    manager.startOnboarding()
                }
                
                FeatureSpotlight(
                    title: "Keyboard Shortcuts",
                    description: "Learn power user navigation shortcuts",
                    icon: "keyboard",
                    color: .purple
                ) {
                    dismiss()
                    KeyboardNavigationManager.shared.showKeyboardShortcuts = true
                }
                
                FeatureSpotlight(
                    title: "Customize Appearance",
                    description: "Set up your preferred theme and contrast",
                    icon: "paintpalette",
                    color: .orange
                ) {
                    dismiss()
                    // Open settings
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                
                FeatureSpotlight(
                    title: "Explore Glossary",
                    description: "50+ scientific terms explained",
                    icon: "text.book.closed",
                    color: .green
                ) {
                    dismiss()
                    KeyboardNavigationManager.shared.toggleGlossary()
                }
            }
            
            Divider()
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Pro Tips")
                    .font(.headline)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Press ⌘/ anytime to see all keyboard shortcuts")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - What's New View

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let updates: [(version: String, features: [String])] = [
        ("1.1", [
            "Interactive neural circuit diagrams",
            "Sortable data tables",
            "High contrast accessibility mode",
            "Keyboard navigation shortcuts"
        ]),
        ("1.0", [
            "Initial release",
            "23 content sections",
            "Interactive timeline",
            "Glossary with 50+ terms"
        ])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("What's New")
                        .font(.title.bold())
                    
                    Text("in APGI Appendix")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Updates list
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(updates, id: \.version) { update in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Version \(update.version)")
                                    .font(.headline)
                                
                                if update.version == updates.first?.version {
                                    Text("NEW")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(update.features, id: \.self) { feature in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text(feature)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Continue button
            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 400, height: 450)
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView()
        .frame(width: 700, height: 550)
}

#Preview("Quick Start") {
    QuickStartPanel()
}

#Preview("What's New") {
    WhatsNewView()
}
