import SwiftUI

// MARK: - Guided Tour View

struct GuidedTour: View {
  @StateObject private var manager = OnboardingManager.shared
  @State private var animateContent = false

  var body: some View {
    ZStack {
      // Background
      LinearGradient(
        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Progress bar
        self.progressBar

        // Main content
        if self.manager.currentStep < self.manager.steps.count {
          self.stepView(
            self.manager.steps[self.manager.currentStep], index: self.manager.currentStep)
        }

        // Navigation buttons
        self.navigationButtons
      }
      .padding(.bottom, 40)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
        self.animateContent = true
      }
    }
  }

  // MARK: - Progress Bar

  private var progressBar: some View {
    HStack(spacing: 6) {
      ForEach(0..<self.manager.steps.count, id: \.self) { index in
        Capsule()
          .fill(
            index <= self.manager.currentStep
              ? self.manager.steps[self.manager.currentStep].highlightColor
              : Color.white.opacity(0.3)
          )
          .frame(height: 4)
          .animation(.spring(response: 0.3), value: self.manager.currentStep)
      }
    }
    .padding(.horizontal, 40)
    .padding(.top, 20)
  }

  // MARK: - Step View

  private func stepView(_ step: OnboardingStep, index _: Int) -> some View {
    VStack(spacing: 24) {
      Spacer()
      self.stepIconView(step: step)
      self.stepContentView(step: step)
      self.stepTipsView(step: step)
      Spacer()
    }
  }

  private func stepIconView(step: OnboardingStep) -> some View {
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
        .symbolEffect(.bounce, value: self.manager.currentStep)
    }
  }

  private func stepContentView(step: OnboardingStep) -> some View {
    VStack(spacing: 12) {
      Text(step.title)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundColor(.white)
      Text(step.subtitle)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(step.highlightColor)
      Text(step.description)
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.9))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
    }
    .scaleEffect(self.animateContent ? 1 : 0.5)
    .opacity(self.animateContent ? 1 : 0)
  }

  private func stepTipsView(step: OnboardingStep) -> some View {
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
        .offset(x: self.animateContent ? 0 : -20)
        .opacity(self.animateContent ? 1 : 0)
        .animation(
          .spring(response: 0.4).delay(Double(tipIndex) * 0.1),
          value: self.animateContent
        )
      }
    }
    .padding(.horizontal, 60)
    .padding(.top, 8)
    .offset(y: self.animateContent ? 0 : 20)
    .opacity(self.animateContent ? 1 : 0)
  }

  // MARK: - Navigation Buttons

  private var navigationButtons: some View {
    HStack(spacing: 16) {
      // Skip button
      if self.manager.currentStep < self.manager.steps.count - 1 {
        Button("Skip") {
          self.manager.completeOnboarding()
        }
        .buttonStyle(.plain)
        .foregroundColor(.white.opacity(0.6))
      }

      Spacer()

      // Previous button
      if self.manager.currentStep > 0 {
        Button("Previous") {
          withAnimation(.spring(response: 0.4)) {
            self.manager.previousStep()
          }
        }
        .buttonStyle(.bordered)
        .foregroundColor(.white)
        .opacity(0.8)
      }

      // Next/Get Started button
      Button(self.manager.currentStep < self.manager.steps.count - 1 ? "Next" : "Get Started") {
        if self.manager.currentStep < self.manager.steps.count - 1 {
          withAnimation(.spring(response: 0.4)) {
            self.manager.nextStep()
          }
        } else {
          self.manager.completeOnboarding()
        }
      }
      .buttonStyle(.borderedProminent)
      .foregroundColor(.white)
    }
    .padding(.horizontal, 40)
    .padding(.bottom, 20)
  }
}

#Preview {
  GuidedTour()
}
