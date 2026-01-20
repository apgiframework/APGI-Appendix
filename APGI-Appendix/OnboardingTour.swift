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

    init(
        title: String,
        subtitle: String,
        description: String,
        imageName: String,
        imageType: ImageType = .system,
        tips: [String] = [],
        highlightColor: Color = .blue
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.imageName = imageName
        self.imageType = imageType
        self.tips = tips
        self.highlightColor = highlightColor
    }
}

enum ImageType {
    case system
    case asset
}

// MARK: - Onboarding Manager
@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var currentStep: Int = 0
    @Published var isShowingTour: Bool = false
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    @Published var completedOnboardingVersion: Int {
        didSet {
            UserDefaults.standard.set(completedOnboardingVersion, forKey: "completedOnboardingVersion")
        }
    }

    let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to APGI Appendix",
            subtitle: "Your comprehensive guide to consciousness research",
            description: "Explore the Allostatic Precision-Gated Ignition framework " +
                "through structured sections, searchable reference material, " +
                "interactive visualizations, and simulation tools.",
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
            description: "Navigate quickly with the sidebar, search, " +
                "and keyboard shortcuts. Jump between sections, " +
                "bookmark key pages, and use focus mode " +
                "for distraction-free reading.",
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
            description: "The integrated APGI Simulator allows you to model " +
                "and visualize neural dynamics in real-time. " +
                "Adjust parameters and observe how different inputs " +
                "affect the ignition process.",
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
            description: "Explore interactive visualizations of circuits " +
                "and connectivity. Pan/zoom, inspect components, " +
                "and connect concepts back to the written sections.",
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
            title: "Ignition Timeline",
            subtitle: "Temporal dynamics visualization",
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
            description: "Customize the app to match your preferences with " +
                "enhanced theming options, font adjustments, and " +
                "accessibility features including VoiceOver support " +
                "and keyboard navigation.",
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
            description: "Some sections now use an enhanced reading layout " +
                "with a hero summary, collapsible subsections, " +
                "and related links for faster navigation " +
                "and cross-referencing.",
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
            description: "You now have all the tools to explore the APGI " +
                "framework. Start with the Methodology section " +
                "for an introduction, or dive into specific " +
                "neural implementations and clinical applications.",
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

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.completedOnboardingVersion = UserDefaults.standard.integer(forKey: "completedOnboardingVersion")
    }

    func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        completedOnboardingVersion = 1
        isShowingTour = false
        currentStep = 0
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        completedOnboardingVersion = 0
    }

    func startOnboarding() {
        currentStep = 0
        isShowingTour = true
    }
}

// MARK: - Onboarding Tour View
struct OnboardingTourView: View {
    @StateObject private var manager = OnboardingManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content

            if manager.isShowingTour {
                GuidedTour()
                    .transition(.opacity)
            }
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
            if !manager.hasCompletedOnboarding {
                manager.startOnboarding()
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Welcome to APGI Appendix")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Spacer()

                Button("Skip Tour") {
                    manager.completeOnboarding()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.7))
            }
            .padding()

            Spacer()

            if !manager.isShowingTour {
                VStack(spacing: 24) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: manager.hasCompletedOnboarding)

                    Text("Explore the APGI Framework")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)

                    Text("Your comprehensive guide to consciousness research")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button("Start Tour") {
                            manager.startOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("Skip") {
                            manager.completeOnboarding()
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding()
            }

            Spacer()
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    OnboardingTourView()
}
