import Combine
import SwiftUI

// MARK: - Tour Highlight View

struct TourHighlight: View {
  let target: TourTarget
  let title: String
  let description: String
  let position: TooltipPosition
  let highlightColor: Color
  let onNext: () -> Void
  let onSkip: () -> Void

  @State private var animateHighlight = false
  @State private var animateTooltip = false
  @State private var pulseScale: CGFloat = 1.0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Dark overlay
        Color.black.opacity(0.65)
          .ignoresSafeArea()

        // Highlight cutout
        self.highlightCutout(geometry: geometry)

        // Tooltip
        self.tooltipView(geometry: geometry)
      }
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.3)) {
        self.animateHighlight = true
      }

      withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
        self.animateTooltip = true
      }

      // Pulse animation for highlight
      withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
        self.pulseScale = 1.1
      }
    }
  }

  // MARK: - Highlight Cutout

  private func highlightCutout(geometry: GeometryProxy) -> some View {
    let targetFrame = self.getTargetFrame(geometry: geometry)

    return ZStack {
      // Main overlay with cutout
      ZStack {
        Color.black.opacity(0.65)

        // Cutout for highlighted area
        RoundedRectangle(cornerRadius: 8)
          .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
          .position(x: targetFrame.midX, y: targetFrame.midY)
          .blendMode(.destinationOut)
      }
      .compositingGroup()

      // Highlight border
      RoundedRectangle(cornerRadius: 8)
        .stroke(self.highlightColor, lineWidth: 3)
        .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
        .position(x: targetFrame.midX, y: targetFrame.midY)
        .scaleEffect(self.pulseScale)
        .opacity(self.animateHighlight ? 0.8 : 0)

      // Glow effect
      RoundedRectangle(cornerRadius: 8)
        .fill(self.highlightColor.opacity(0.2))
        .frame(width: targetFrame.width + 30, height: targetFrame.height + 30)
        .position(x: targetFrame.midX, y: targetFrame.midY)
        .blur(radius: 15)
        .opacity(self.animateHighlight ? 0.6 : 0)
    }
  }

  // MARK: - Tooltip View

  private func tooltipView(geometry: GeometryProxy) -> some View {
    let targetFrame = self.getTargetFrame(geometry: geometry)
    let tooltipPosition = self.calculateTooltipPosition(
      targetFrame: targetFrame, geometry: geometry)

    return VStack(spacing: 0) {
      // Content arrow
      self.tooltipArrow(position: self.position)

      // Tooltip content
      VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack {
          Image(systemName: self.target.icon)
            .font(.title2)
            .foregroundColor(self.highlightColor)

          Text(self.target.name)
            .font(.headline)
            .foregroundColor(.primary)

          Spacer()
        }

        // Title
        Text(self.title)
          .font(.title3.weight(.semibold))
          .foregroundColor(.primary)

        // Description
        Text(self.description)
          .font(.body)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        // Navigation buttons
        HStack {
          Button("Skip") {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.onSkip()
            }
          }
          .buttonStyle(.plain)
          .foregroundColor(.secondary)

          Spacer()

          Button("Next") {
            withAnimation(.easeInOut(duration: 0.3)) {
              self.onNext()
            }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }
        .padding(.top, 8)
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(NSColor.controlBackgroundColor))
          .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
      )
      .frame(maxWidth: 280)
    }
    .position(x: tooltipPosition.x, y: tooltipPosition.y)
    .scaleEffect(self.animateTooltip ? 1 : 0.8)
    .opacity(self.animateTooltip ? 1 : 0)
  }

  // MARK: - Tooltip Arrow

  private func tooltipArrow(position: TooltipPosition) -> some View {
    Group {
      switch position {
      case .top:
        VStack(spacing: 0) {
          ArrowShape(direction: .down)
            .fill(Color(NSColor.controlBackgroundColor))
            .frame(width: 20, height: 10)
            .offset(y: -1)
        }
      case .bottom:
        VStack(spacing: 0) {
          ArrowShape(direction: .up)
            .fill(Color(NSColor.controlBackgroundColor))
            .frame(width: 20, height: 10)
            .offset(y: 1)
        }
      case .leading:
        HStack(spacing: 0) {
          ArrowShape(direction: .right)
            .fill(Color(NSColor.controlBackgroundColor))
            .frame(width: 10, height: 20)
            .offset(x: -1)
        }
      case .trailing:
        HStack(spacing: 0) {
          ArrowShape(direction: .left)
            .fill(Color(NSColor.controlBackgroundColor))
            .frame(width: 10, height: 20)
            .offset(x: 1)
        }
      case .center:
        EmptyView()
      }
    }
  }

  // MARK: - Helper Methods

  private func getTargetFrame(geometry: GeometryProxy) -> CGRect {
    let screenSize = geometry.size

    switch self.target {
    case .sidebar:
      return CGRect(x: 20, y: 100, width: 250, height: screenSize.height - 200)
    case .search:
      return CGRect(x: 300, y: 60, width: 200, height: 40)
    case .content:
      return CGRect(x: 520, y: 100, width: screenSize.width - 540, height: screenSize.height - 200)
    case .toolbar:
      return CGRect(x: 300, y: 10, width: screenSize.width - 320, height: 50)
    case .settings:
      return CGRect(x: screenSize.width - 100, y: 20, width: 60, height: 30)
    case .simulator:
      return CGRect(x: 100, y: 200, width: 300, height: 200)
    case .timeline:
      return CGRect(x: 450, y: 200, width: 300, height: 200)
    case .bookmarks:
      return CGRect(x: screenSize.width - 200, y: 100, width: 150, height: 100)
    }
  }

  private func calculateTooltipPosition(targetFrame: CGRect, geometry: GeometryProxy) -> CGPoint {
    let tooltipWidth: CGFloat = 280
    let tooltipHeight: CGFloat = 200
    let padding: CGFloat = 20

    switch self.position {
    case .top:
      return CGPoint(
        x: min(
          max(targetFrame.midX, tooltipWidth / 2 + padding),
          geometry.size.width - tooltipWidth / 2 - padding),
        y: targetFrame.minY - tooltipHeight / 2 - 30
      )
    case .bottom:
      return CGPoint(
        x: min(
          max(targetFrame.midX, tooltipWidth / 2 + padding),
          geometry.size.width - tooltipWidth / 2 - padding),
        y: targetFrame.maxY + tooltipHeight / 2 + 30
      )
    case .leading:
      return CGPoint(
        x: targetFrame.minX - tooltipWidth / 2 - 30,
        y: min(
          max(targetFrame.midY, tooltipHeight / 2 + padding),
          geometry.size.height - tooltipHeight / 2 - padding)
      )
    case .trailing:
      return CGPoint(
        x: targetFrame.maxX + tooltipWidth / 2 + 30,
        y: min(
          max(targetFrame.midY, tooltipHeight / 2 + padding),
          geometry.size.height - tooltipHeight / 2 - padding)
      )
    case .center:
      return CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
  }
}

// MARK: - Arrow Shape

struct ArrowShape: Shape {
  enum Direction {
    case up, down, left, right
  }

  let direction: Direction

  func path(in rect: CGRect) -> Path {
    var path = Path()

    switch self.direction {
    case .up:
      path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    case .down:
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    case .left:
      path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    case .right:
      path.move(to: CGPoint(x: rect.minX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    }

    path.closeSubpath()
    return path
  }
}

// MARK: - Tour Highlight Manager

@MainActor
class TourHighlightManager: ObservableObject {
  static let shared = TourHighlightManager()

  @Published var isShowingHighlight = false
  @Published var currentStep: TourStep?
  @Published var tourSteps: [TourStep] = []

  private var currentStepIndex = 0

  func startTour(steps: [TourStep]) {
    self.tourSteps = steps
    self.currentStepIndex = 0
    self.showStep(at: 0)
  }

  func nextStep() {
    if self.currentStepIndex < self.tourSteps.count - 1 {
      self.currentStepIndex += 1
      self.showStep(at: self.currentStepIndex)
    } else {
      self.completeTour()
    }
  }

  func skipTour() {
    self.completeTour()
  }

  private func showStep(at index: Int) {
    guard index < self.tourSteps.count else { return }
    self.currentStep = self.tourSteps[index]
    self.isShowingHighlight = true

    // Execute action if available
    self.currentStep?.action?()
  }

  private func completeTour() {
    self.isShowingHighlight = false
    self.currentStep = nil
    self.currentStepIndex = 0
  }
}

// MARK: - Tour Highlight Overlay

struct TourHighlightOverlay: View {
  @StateObject private var tourManager = TourHighlightManager.shared

  var body: some View {
    Group {
      if self.tourManager.isShowingHighlight, let step = tourManager.currentStep {
        TourHighlight(
          target: step.target,
          title: step.title,
          description: step.description,
          position: step.position,
          highlightColor: step.highlightColor,
          onNext: self.tourManager.nextStep,
          onSkip: self.tourManager.skipTour
        )
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
      }
    }
    .animation(.easeInOut(duration: 0.3), value: self.tourManager.isShowingHighlight)
  }
}

#Preview {
  TourHighlight(
    target: .sidebar,
    title: "Navigation Sidebar",
    description:
      "Browse all sections of the APGI framework from here. Use the sidebar to quickly jump between different topics and categories.",
    position: .trailing,
    highlightColor: .blue,
    onNext: {
    },
    onSkip: {
    }
  )
}
