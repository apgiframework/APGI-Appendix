import SwiftUI
import AppKit
import Combine

// MARK: - Tour Data Model

enum TourTarget {
    case sidebar
    case search
    case glossary
    case simulator
    case timeline
    case settings
    case navigation
}

enum TooltipPosition {
    case above
    case below
    case left
    case right
    case center
}

struct TourStep: Identifiable {
    let id = UUID()
    let target: TourTarget
    let title: String
    let description: String
    let position: TooltipPosition
    let highlightColor: Color
    let action: (() -> Void)?

    init(target: TourTarget, title: String, description: String, position: TooltipPosition, highlightColor: Color = .blue, action: (() -> Void)? = nil) {
        self.target = target
        self.title = title
        self.description = description
        self.position = position
        self.highlightColor = highlightColor
        self.action = action
    }
}

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
    @Published var isShowingTour = false
    @Published var currentStep = 0
    @Published var currentTourStep = 0

    private let currentOnboardingVersion = 2

    private init() {}

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding || completedOnboardingVersion < currentOnboardingVersion
    }

    func startOnboarding() {
        currentStep = 0
        isShowingOnboarding = true
    }

    func startTour() {
        currentTourStep = 0
        isShowingTour = true
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        completedOnboardingVersion = currentOnboardingVersion
        isShowingOnboarding = false
    }

    func completeTour() {
        isShowingTour = false
        currentTourStep = 0
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        completedOnboardingVersion = 0
    }

    let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to APGI Appendix",
            subtitle: "Your comprehensive guide to consciousness research",
            description: "Explore the Allostatic Precision-Gated Ignition framework through structured sections, searchable reference material, interactive visualizations, and simulation tools.",
            imageName: "brain.head.profile",
            imageType: .system,
            tips: [
                "Browse sections by category",
                "Enhanced reading layout with key takeaways and collapsible subsections",
                "Glossary-highlighted terms for fast definitions",
                "APGI Simulator window for interactive modeling",
                "Dark/light mode support"
            ],
            highlightColor: .blue
        ),
        OnboardingStep(
            title: "Enhanced Navigation",
            subtitle: "Intelligent content discovery",
            description: "Navigate quickly with the sidebar, search, and keyboard shortcuts. Jump between sections, bookmark key pages, and use focus mode for distraction-free reading.",
            imageName: "sidebar.leading",
            imageType: .system,
            tips: [
                "⌘1-9: Jump to main sections",
                "⌘F: Search",
                "⌘↑/↓: Navigate between sections"
            ],
            highlightColor: .purple
        ),
        OnboardingStep(
            title: "APGI Simulator",
            subtitle: "Interactive neural modeling",
            description: "The integrated APGI Simulator allows you to model and visualize neural dynamics in real-time. Adjust parameters and observe how different inputs affect the ignition process.",
            imageName: "chart.line.uptrend.xyaxis",
            imageType: .system,
            tips: [
                "⌘⇧M: Open simulator window",
                "Adjust parameters with sliders",
                "Real-time visualization updates",
                "Save and load model configurations"
            ],
            highlightColor: .teal
        ),
        OnboardingStep(
            title: "Neural Circuit Explorer",
            subtitle: "3D interactive visualizations",
            description: "Explore interactive visualizations of circuits and connectivity. Pan/zoom, inspect components, and connect concepts back to the written sections.",
            imageName: "circle.hexagongrid",
            imageType: .system,
            tips: [
                "Click and drag to explore",
                "Scroll/trackpad to zoom",
                "Use labels to orient yourself"
            ],
            highlightColor: .indigo
        ),
        OnboardingStep(
            title: "Enhanced Timeline",
            subtitle: "Visualize neural dynamics",
            description: "Open the Ignition Timeline window to explore temporal dynamics and stage progression.",
            imageName: "timeline.selection",
            imageType: .system,
            tips: [
                "⌘⇧T: Open timeline window",
                "Use zoom controls for scale",
                "Tap/inspect events for details"
            ],
            highlightColor: .orange
        ),
        OnboardingStep(
            title: "Accessibility & Customization",
            subtitle: "Tailor your experience",
            description: "Customize the app to match your preferences with enhanced theming options, font adjustments, and accessibility features including VoiceOver support and keyboard navigation.",
            imageName: "paintpalette",
            imageType: .system,
            tips: [
                "⌘,: Open Settings",
                "⌘0: Reset zoom",
                "⌘++/--: Adjust text size",
                "Full VoiceOver support"
            ],
            highlightColor: .green
        ),
        OnboardingStep(
            title: "Enhanced Reading",
            subtitle: "Better visual hierarchy",
            description: "Some sections now use an enhanced reading layout with a hero summary, collapsible subsections, and related links for faster navigation and cross-referencing.",
            imageName: "doc.text.image",
            imageType: .system,
            tips: [
                "Start with the hero card for the key takeaway",
                "Expand only the subsections you need",
                "Use Related links to jump across the framework"
            ],
            highlightColor: .purple
        ),
        OnboardingStep(
            title: "You're All Set!",
            subtitle: "Begin your APGI journey",
            description: "You now have all the tools to explore the APGI framework. Start with the Methodology section for an introduction, or dive into specific neural implementations and clinical applications.",
            imageName: "checkmark.seal.fill",
            imageType: .system,
            tips: [
                "⌘?: Quick help anytime",
                "Right-click for context menus",
                "Drag and drop to reorganize",
                "Check back for updates"
            ],
            highlightColor: .blue
        )
    ]

    let tourSteps: [TourStep] = [
        TourStep(
            target: .sidebar,
            title: "Navigate the Framework",
            description: "Browse sections organized by category. Start with Foundations for core concepts.",
            position: .right,
            highlightColor: .blue
        ),
        TourStep(
            target: .search,
            title: "Search Everything",
            description: "Find any term, formula, or concept across all sections and the glossary.",
            position: .below,
            highlightColor: .purple
        ),
        TourStep(
            target: .glossary,
            title: "Tap Any Term",
            description: "Technical terms are highlighted. Tap for instant definitions.",
            position: .above,
            highlightColor: .green
        ),
        TourStep(
            target: .simulator,
            title: "Explore Interactively",
            description: "Adjust parameters and watch ignition dynamics in real-time.",
            position: .left,
            highlightColor: .teal
        ),
        TourStep(
            target: .timeline,
            title: "Visualize the Process",
            description: "Watch the 500ms journey from stimulus to conscious access.",
            position: .below,
            highlightColor: .orange
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
            if ThemeManager.shared.enableAnimations {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    animateContent = true
                }
            } else {
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
                    if ThemeManager.shared.enableAnimations {
                        withAnimation {
                            manager.currentStep -= 1
                        }
                    } else {
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
                    if ThemeManager.shared.enableAnimations {
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
                        manager.currentStep += 1
                        animateContent = true
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


// MARK: - Spotlight Overlay

struct SpotlightOverlay: View {
    let target: TourTarget
    @State private var targetFrame: CGRect = .zero
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay with gradient effect
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Spotlight cutout with smooth edges
                Path { path in
                    path.addRect(geometry.frame(in: .global))

                    // Create rounded rectangle cutout for smoother appearance
                    let roundedRect = RoundedRectangle(cornerRadius: 12)
                        .inset(by: -4)
                        .path(in: targetFrame)
                    path.addPath(roundedRect)
                }
                .fill(Color.black.opacity(0.7))
                .blendMode(.destinationOut)

                // Animated highlight border around target
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: targetFrame.width + 16, height: targetFrame.height + 16)
                        .scaleEffect(pulseScale)
                        .rotationEffect(.degrees(rotation))

                    // Inner border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: targetFrame.width + 8, height: targetFrame.height + 8)
                }
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isAnimating)

                // Corner indicators
                if isAnimating {
                    ForEach(0..<4, id: \.self) { corner in
                        cornerIndicator(at: corner, in: targetFrame)
                    }
                }
            }
        }
        .onAppear {
            findTargetFrame()
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                isAnimating = true
            }
            startAnimations()
        }
        .onChange(of: target) { _, _ in
            isAnimating = false
            findTargetFrame()
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                isAnimating = true
            }
        }
    }

    private func cornerIndicator(at corner: Int, in frame: CGRect) -> some View {
        let positions = [
            CGPoint(x: frame.minX, y: frame.minY),
            CGPoint(x: frame.maxX, y: frame.minY),
            CGPoint(x: frame.maxX, y: frame.maxY),
            CGPoint(x: frame.minX, y: frame.maxY)
        ]

        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)

            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 16, height: 16)
                .opacity(0.6)
        }
        .position(positions[corner])
        .scaleEffect(pulseScale)
        .animation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
            .delay(Double(corner) * 0.2),
            value: pulseScale
        )
    }

    private func startAnimations() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
            rotation = 5.0
        }
    }

    private func findTargetFrame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            switch target {
            case .sidebar:
                targetFrame = CGRect(x: 50, y: 100, width: 250, height: 400)
            case .search:
                targetFrame = CGRect(x: 300, y: 50, width: 200, height: 40)
            case .glossary:
                targetFrame = CGRect(x: 550, y: 100, width: 150, height: 40)
            case .simulator:
                targetFrame = CGRect(x: 400, y: 300, width: 200, height: 150)
            case .timeline:
                targetFrame = CGRect(x: 100, y: 500, width: 600, height: 200)
            case .settings:
                targetFrame = CGRect(x: 700, y: 50, width: 40, height: 40)
            case .navigation:
                targetFrame = CGRect(x: 200, y: 200, width: 400, height: 60)
            }
        }
    }
}

// MARK: - Tour Tooltip

struct TourTooltip: View {
    let step: TourStep
    @State private var isVisible = false
    @State private var contentOffset: CGSize = .zero
    @State private var glowIntensity: Double = 0.0
    @ObservedObject private var manager = OnboardingManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with animated indicator
            HStack {
                ZStack {
                    Circle()
                        .fill(step.highlightColor.opacity(0.2))
                        .frame(width: 16, height: 16)
                        .scaleEffect(glowIntensity)

                    Circle()
                        .fill(step.highlightColor)
                        .frame(width: 8, height: 8)
                        .symbolEffect(.pulse, value: isVisible)
                }

                Text(step.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Step indicator with animation
                HStack(spacing: 4) {
                    ForEach(0..<manager.tourSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= manager.currentTourStep ? step.highlightColor : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .animation(.spring(response: 0.3), value: manager.currentTourStep)
                    }
                }
            }

            // Description with typewriter effect
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.6).delay(0.3), value: isVisible)

            // Navigation buttons with enhanced styling
            HStack {
                // Skip button
                Button("Skip Tour") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        manager.completeTour()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
                .scaleEffect(isVisible ? 1 : 0.8)

                Spacer()

                // Back button
                if manager.currentTourStep > 0 {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            manager.currentTourStep -= 1
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

                // Next button
                Button {
                    if manager.currentTourStep < manager.tourSteps.count - 1 {
                        withAnimation(.spring(response: 0.4)) {
                            manager.currentTourStep += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            manager.completeTour()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(manager.currentTourStep < manager.tourSteps.count - 1 ? "Next" : "Finish")
                        Image(systemName: manager.currentTourStep < manager.tourSteps.count - 1
                              ? "chevron.right"
                              : "checkmark")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(step.highlightColor)
                .scaleEffect(isVisible ? 1 : 0.95)
                .shadow(color: step.highlightColor.opacity(0.3), radius: 4)
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Background with glass effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThinMaterial)
                    )

                // Subtle glow effect
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                step.highlightColor.opacity(glowIntensity),
                                step.highlightColor.opacity(glowIntensity * 0.5),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .frame(maxWidth: 280)
        .shadow(color: .black.opacity(0.2), radius: 20)
        .scaleEffect(isVisible ? 1 : 0.8)
        .offset(contentOffset)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .animation(.spring(response: 0.6), value: contentOffset)
        .onAppear {
            withAnimation(.spring(response: 0.4).delay(0.5)) {
                isVisible = true
                contentOffset = .zero
            }
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                glowIntensity = 0.6
            }
        }
        .onChange(of: manager.currentTourStep) { _, _ in
            isVisible = false
            contentOffset = CGSize(width: 10, height: 10)

            withAnimation(.spring(response: 0.4).delay(0.3)) {
                isVisible = true
                contentOffset = .zero
            }
        }
        .position(tooltipPosition)
    }

    private var tooltipPosition: CGPoint {
        switch step.target {
        case .sidebar:
            return CGPoint(x: 350, y: 300)
        case .search:
            return CGPoint(x: 400, y: 120)
        case .glossary:
            return CGPoint(x: 625, y: 160)
        case .simulator:
            return CGPoint(x: 300, y: 375)
        case .timeline:
            return CGPoint(x: 400, y: 650)
        case .settings:
            return CGPoint(x: 650, y: 120)
        case .navigation:
            return CGPoint(x: 400, y: 280)
        }
    }
}

// MARK: - Guided Tour

struct GuidedTour: View {
    @EnvironmentObject var onboardingManager: OnboardingManager

    let steps: [TourStep] = [
        TourStep(
            target: .sidebar,
            title: "Navigate the Framework",
            description: "Browse sections organized by category. Start with Foundations for core concepts.",
            position: .right
        ),
        TourStep(
            target: .search,
            title: "Search Everything",
            description: "Find any term, formula, or concept across all sections and the glossary.",
            position: .below
        ),
        TourStep(
            target: .glossary,
            title: "Tap Any Term",
            description: "Technical terms are highlighted. Tap for instant definitions.",
            position: .above
        ),
        TourStep(
            target: .simulator,
            title: "Explore Interactively",
            description: "Adjust parameters and watch ignition dynamics in real-time.",
            position: .left
        ),
        TourStep(
            target: .timeline,
            title: "Visualize the Process",
            description: "Watch the 500ms journey from stimulus to conscious access.",
            position: .below
        )
    ]

    var body: some View {
        ZStack {
            // Dimmed overlay with spotlight on current target
            SpotlightOverlay(target: steps[onboardingManager.currentTourStep].target)

            // Tooltip at appropriate position
            TourTooltip(step: steps[onboardingManager.currentTourStep])
        }
        .ignoresSafeArea()
    }
}

// MARK: - Tour Container

struct TourContainer<Content: View>: View {
    @ObservedObject private var manager = OnboardingManager.shared
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            content()

            if manager.isShowingTour {
                GuidedTour()
                    .transition(.opacity)
            }
        }
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
