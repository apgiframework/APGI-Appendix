import Combine
import SwiftUI

struct EnhancedTimelineView: View {
  @State private var currentTime: Int = 0
  @State private var isPlaying = false
  @State private var selectedEvent: TimelineEvent?
  @State private var playbackSpeed: Double = 1.0
  @State private var showPhaseIndicators = true

  private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
  private let maxTime = 500
  private let events = TimelineEvent.sampleEvents

  var body: some View {
    VStack(spacing: APGISpacing.xl) {
      PlaybackControls(
        isPlaying: self.$isPlaying,
        currentTime: self.$currentTime,
        playbackSpeed: self.$playbackSpeed,
        maxTime: self.maxTime,
        onReset: self.reset
      )

      GeometryReader { geometry in
        ZStack(alignment: .topLeading) {
          TimelineGrid(maxTime: self.maxTime)

          if self.showPhaseIndicators {
            PhaseRegions(maxTime: self.maxTime)
              .opacity(0.15)
          }

          ForEach(self.events) { event in
            EnhancedEventBlock(
              event: event,
              isSelected: self.selectedEvent?.id == event.id,
              currentTime: self.currentTime,
              totalWidth: geometry.size.width,
              maxTime: self.maxTime
            )
            .onTapGesture {
              withAnimation(.spring(response: 0.3)) {
                self.selectedEvent = event
              }
            }
          }

          PlayheadIndicator(
            currentTime: self.currentTime,
            maxTime: self.maxTime
          )
        }
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              withAnimation(.interactiveSpring()) {
                self.isPlaying = false
                let ratio = min(max(0, value.location.x / max(1, geometry.size.width)), 1)
                self.currentTime = Int(ratio * Double(self.maxTime))
              }
            }
        )
      }
      .frame(height: 180)
      .background(.quaternary.opacity(0.2))
      .clipShape(RoundedRectangle(cornerRadius: APGISpacing.lg))

      TimeMarkers()

      if let event = selectedEvent {
        EventDetailsPanel(event: event)
          .transition(
            .asymmetric(
              insertion: .move(edge: .bottom).combined(with: .opacity),
              removal: .opacity
            ))
      }
    }
    .padding(APGISpacing.xl)
    .onReceive(self.timer) { _ in
      guard self.isPlaying else { return }
      withAnimation(.linear(duration: 0.016)) {
        if self.currentTime < self.maxTime {
          self.currentTime = min(self.maxTime, self.currentTime + Int(self.playbackSpeed * 10))
        } else {
          self.isPlaying = false
          self.currentTime = 0
        }
      }
    }
  }

  private func reset() {
    withAnimation(.easeInOut(duration: 0.2)) {
      self.currentTime = 0
      self.isPlaying = false
    }
  }
}

struct EventDetailsPanel: View {
  let event: TimelineEvent

  var body: some View {
    VStack(alignment: .leading, spacing: APGISpacing.md) {
      HStack(alignment: .firstTextBaseline, spacing: APGISpacing.sm) {
        Circle()
          .fill(self.event.category.color)
          .frame(width: 12, height: 12)

        Text(self.event.title)
          .font(APGITypography.h3)

        Text("\(self.event.timeRange.lowerBound)–\(self.event.timeRange.upperBound)ms")
          .font(APGITypography.body)
          .foregroundStyle(.secondary)

        Spacer()

        Text(self.event.phase.rawValue)
          .font(APGITypography.micro)
          .padding(.horizontal, APGISpacing.sm)
          .padding(.vertical, APGISpacing.xs)
          .background(self.event.phase.color.opacity(0.2))
          .foregroundStyle(self.event.phase.color)
          .clipShape(Capsule())
      }

      GlossaryHighlightedText(text: self.event.description)
        .font(APGITypography.body)
        .foregroundStyle(.secondary)
        .lineSpacing(4)
    }
    .padding(APGISpacing.lg)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: APGISpacing.lg))
    .overlay {
      RoundedRectangle(cornerRadius: APGISpacing.lg)
        .strokeBorder(self.event.category.color.opacity(0.3), lineWidth: 1.5)
    }
    .shadow(color: self.event.category.color.opacity(0.2), radius: 8, y: 4)
  }
}

struct TimeMarkers: View {
  var body: some View {
    HStack(spacing: 0) {
      ForEach([0, 100, 200, 300, 400, 500], id: \.self) { time in
        Text("\(time)ms")
          .font(APGITypography.micro)
          .foregroundStyle(.secondary)
          .frame(
            maxWidth: .infinity,
            alignment: {
              if time == 0 {
                return .leading
              } else if time == 500 {
                return .trailing
              } else {
                return .center
              }
            }()
          )
      }
    }
  }
}

struct EnhancedInteractiveTimeline: View {
  @State private var currentTime: Int = 0
  @State private var isPlaying = false
  @State private var selectedEvent: TimelineEvent?
  @State private var playbackSpeed: Double = 1.0
  @State private var showPhaseIndicators = true
  @State private var hoveredEvent: TimelineEvent?

  private let tickInterval: TimeInterval = 0.016
  private let maxTime = 500
  private let events = TimelineEvent.sampleEvents

  private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

  init() {
    self.timer = Timer.publish(every: self.tickInterval, on: .main, in: .common).autoconnect()
  }

  var body: some View {
    VStack(spacing: APGISpacing.xl) {
      self.headerSection
      self.timelineSection
      self.timeMarkersSection

      if let event = selectedEvent {
        self.eventDetailsPanel(for: event)
      }
    }
    .padding(APGISpacing.xl)
    .onReceive(self.timer) { _ in
      self.updatePlayback()
    }
    .onAppear {
      self.selectedEvent = self.events.first
    }
  }

  private var headerSection: some View {
    VStack(spacing: APGISpacing.md) {
      HStack {
        Text("Ignition Timeline")
          .font(APGITypography.h2)

        Spacer()

        Toggle(isOn: self.$showPhaseIndicators) {
          Label("Show Phases", systemImage: "square.3.layers.3d")
            .font(APGITypography.label)
        }
        .toggleStyle(.button)
        .accessibilityLabel("Show phase indicators")
        .accessibilityHint("Toggles the display of colored phase regions on the timeline")
      }

      PlaybackControls(
        isPlaying: self.$isPlaying,
        currentTime: self.$currentTime,
        playbackSpeed: self.$playbackSpeed,
        maxTime: self.maxTime,
        onReset: self.reset
      )
    }
  }

  private var timelineSection: some View {
    GeometryReader { geometry in
      self.timelineContent(geometry: geometry)
    }
    .frame(height: 200)
    .background(
      RoundedRectangle(cornerRadius: APGISpacing.lg)
        .fill(.ultraThinMaterial)
    )
    .overlay {
      RoundedRectangle(cornerRadius: APGISpacing.lg)
        .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
    }
  }

  private func timelineContent(geometry: GeometryProxy) -> some View {
    ZStack(alignment: .topLeading) {
      TimelineGrid(maxTime: self.maxTime)

      if self.showPhaseIndicators {
        PhaseRegions(maxTime: self.maxTime)
          .opacity(0.15)
          .transition(.opacity)
      }

      self.eventBlocksView(geometry: geometry)

      PlayheadIndicator(
        currentTime: self.currentTime,
        maxTime: self.maxTime
      )
    }
    .gesture(self.scrubGesture(geometry: geometry))
    .accessibilityLabel("Ignition timeline scrubber")
    .accessibilityHint("Drag to scrub through the timeline or use arrow keys to navigate")
    .accessibilityValue("\(self.currentTime) milliseconds")
    .accessibilityAction(named: "Move to previous event") {
      self.moveToPreviousEvent()
    }
    .accessibilityAction(named: "Move to next event") {
      self.moveToNextEvent()
    }
  }

  private func eventBlocksView(geometry: GeometryProxy) -> some View {
    ForEach(self.events) { event in
      EventBlock(
        event: event,
        isSelected: self.selectedEvent?.id == event.id,
        isHovered: self.hoveredEvent?.id == event.id,
        currentTime: self.currentTime,
        totalWidth: geometry.size.width,
        maxTime: self.maxTime
      )
      .onTapGesture {
        withAnimation(.easeInOut(duration: 0.2)) {
          self.selectedEvent = event
        }
      }
      .onHover { hovering in
        self.hoveredEvent = hovering ? event : nil
      }
      .accessibilityLabel(
        "\(event.title), \(event.timeRange.lowerBound) to \(event.timeRange.upperBound) milliseconds"
      )
      .accessibilityHint("Tap to view details for this ignition phase")
      .accessibilityAddTraits(.isButton)
    }
  }

  private func scrubGesture(geometry: GeometryProxy) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        withAnimation(.interactiveSpring()) {
          self.isPlaying = false
          let ratio = min(max(0, value.location.x / max(1, geometry.size.width)), 1)
          self.currentTime = Int(ratio * Double(self.maxTime))
        }
      }
  }

  private func moveToPreviousEvent() {
    if let currentEvent = events.first(where: { $0.timeRange.contains(currentTime) }),
      let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
      currentIndex > 0 {
      let previousEvent = self.events[currentIndex - 1]
      self.currentTime = previousEvent.timeRange.lowerBound
      self.selectedEvent = previousEvent
    }
  }

  private func moveToNextEvent() {
    if let currentEvent = events.first(where: { $0.timeRange.contains(currentTime) }),
      let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
      currentIndex < events.count - 1 {
      let nextEvent = self.events[currentIndex + 1]
      self.currentTime = nextEvent.timeRange.lowerBound
      self.selectedEvent = nextEvent
    }
  }

  private var timeMarkersSection: some View {
    HStack(spacing: 0) {
      ForEach([0, 100, 200, 300, 400, 500], id: \.self) { time in
        Text("\(time)ms")
          .font(APGITypography.micro)
          .foregroundStyle(.secondary)
          .frame(
            maxWidth: .infinity,
            alignment: {
              if time == 0 {
                return .leading
              } else if time == self.maxTime {
                return .trailing
              } else {
                return .center
              }
            }()
          )
      }
    }
  }

  private func eventDetailsPanel(for event: TimelineEvent) -> some View {
    VStack(alignment: .leading, spacing: APGISpacing.md) {
      HStack(alignment: .firstTextBaseline, spacing: APGISpacing.sm) {
        Circle()
          .fill(event.category.color)
          .frame(width: 12, height: 12)

        Text(event.title)
          .font(APGITypography.h3)

        Text("(\(event.timeRange.lowerBound)–\(event.timeRange.upperBound)ms)")
          .font(APGITypography.body)
          .foregroundStyle(.secondary)

        Spacer()

        Text(event.phase.rawValue)
          .font(APGITypography.micro)
          .padding(.horizontal, APGISpacing.sm)
          .padding(.vertical, APGISpacing.xs)
          .background(event.phase.color.opacity(0.2))
          .foregroundStyle(event.phase.color)
          .clipShape(Capsule())
      }

      GlossaryHighlightedText(text: event.description)
        .font(APGITypography.body)
        .foregroundStyle(.secondary)
        .lineSpacing(4)

      if self.currentTime >= event.timeRange.lowerBound
        && self.currentTime <= event.timeRange.upperBound {
        EventProgressBar(
          currentTime: self.currentTime,
          event: event
        )
      }
    }
    .padding(APGISpacing.lg)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: APGISpacing.lg))
    .overlay {
      RoundedRectangle(cornerRadius: APGISpacing.lg)
        .strokeBorder(event.category.color.opacity(0.3), lineWidth: 1.5)
    }
    .shadow(color: event.category.color.opacity(0.2), radius: 8, y: 4)
    .transition(
      .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .opacity
      ))
  }

  private func updatePlayback() {
    guard self.isPlaying else { return }
    withAnimation(.linear(duration: self.tickInterval)) {
      if self.currentTime < self.maxTime {
        self.currentTime = min(self.maxTime, self.currentTime + Int(self.playbackSpeed * 10))
      } else {
        self.isPlaying = false
        self.currentTime = 0
      }
    }
  }

  private func reset() {
    withAnimation(.easeInOut(duration: 0.2)) {
      self.currentTime = 0
      self.isPlaying = false
    }
  }
}

struct PlaybackControls: View {
  @Binding var isPlaying: Bool
  @Binding var currentTime: Int
  @Binding var playbackSpeed: Double
  let maxTime: Int
  let onReset: () -> Void

  var body: some View {
    HStack(spacing: APGISpacing.lg) {
      Button(action: { self.isPlaying.toggle() }, label: {
        Image(systemName: self.isPlaying ? "pause.circle.fill" : "play.circle.fill")
          .font(.title)
          .foregroundStyle(Color.accentColor)
      })
      .buttonStyle(.plain)
      .accessibilityLabel(self.isPlaying ? "Pause timeline animation" : "Play timeline animation")
      .accessibilityHint("Controls the automatic progression through the ignition timeline")

      Button(action: self.onReset) {
        Image(systemName: "arrow.counterclockwise.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Reset timeline")
      .accessibilityHint("Returns the timeline to the beginning")

      Text("\(self.currentTime)ms")
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundStyle(.primary)
        .frame(width: 60, alignment: .trailing)
        .accessibilityLabel("Current time: \(self.currentTime) milliseconds")

      Spacer()

      HStack(spacing: APGISpacing.sm) {
        Text("Speed:")
          .font(APGITypography.label)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)  // Label for the speed controls

        ForEach([0.5, 1.0, 2.0], id: \.self) { speed in
          Button(action: { self.playbackSpeed = speed }, label: {
            Text("\(speed, specifier: "%.1f")x")
              .font(APGITypography.label)
              .foregroundStyle(self.playbackSpeed == speed ? .white : .primary)
              .padding(.horizontal, APGISpacing.sm)
              .padding(.vertical, APGISpacing.xs)
              .background(
                self.playbackSpeed == speed
                  ? Color.accentColor
                  : Color.clear
              )
              .clipShape(Capsule())
          })
          .buttonStyle(.plain)
          .accessibilityLabel("Playback speed \(speed, specifier: "%.1f") times")
          .accessibilityHint("Changes the speed of timeline animation")
        }
      }
    }
  }
}

struct EventBlock: View {
  let event: TimelineEvent
  let isSelected: Bool
  let isHovered: Bool
  let currentTime: Int
  let totalWidth: CGFloat
  let maxTime: Int

  var body: some View {
    let startX = CGFloat(event.timeRange.lowerBound) / CGFloat(self.maxTime) * self.totalWidth
    let width =
      CGFloat(event.timeRange.upperBound - self.event.timeRange.lowerBound) / CGFloat(self.maxTime)
      * self.totalWidth
    let isActive =
      self.currentTime >= self.event.timeRange.lowerBound
      && self.currentTime <= self.event.timeRange.upperBound

    VStack(alignment: .leading, spacing: 4) {
      Text(self.event.title)
        .font(APGITypography.micro)
        .foregroundStyle(self.isSelected ? .white : .primary)
        .lineLimit(1)

      RoundedRectangle(cornerRadius: APGISpacing.sm)
        .fill(
          LinearGradient(
            colors: [
              self.event.category.color.opacity(isActive ? 1.0 : 0.7),
              self.event.category.color.opacity(isActive ? 0.8 : 0.5)
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: max(width, 40), height: 36)
        .overlay {
          if isActive {
            RoundedRectangle(cornerRadius: APGISpacing.sm)
              .stroke(self.event.category.color, lineWidth: 2)
              .opacity(0.5)
              .scaleEffect(1.1)
              .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isActive
              )
          }
        }
        .shadow(
          color: self.event.category.color.opacity(isActive ? 0.4 : 0.2),
          radius: isActive ? 8 : 4,
          y: 2
        )
    }
    .padding(.horizontal, APGISpacing.xs)
    .padding(.vertical, APGISpacing.xs)
    .background(self.isSelected ? self.event.category.color.opacity(0.35) : Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: APGISpacing.md))
    .offset(x: startX, y: 20)
    .scaleEffect(
      {
        if self.isSelected {
          return 1.05
        } else if self.isHovered {
          return 1.02
        } else {
          return 1.0
        }
      }()
    )
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: self.isSelected)
    .animation(.easeInOut(duration: 0.15), value: isActive)
  }
}

struct EnhancedEventBlock: View {
  let event: TimelineEvent
  let isSelected: Bool
  let currentTime: Int
  let totalWidth: CGFloat
  let maxTime: Int

  @State private var isHovered = false

  var body: some View {
    let startX = CGFloat(event.timeRange.lowerBound) / CGFloat(self.maxTime) * self.totalWidth
    let width =
      CGFloat(event.timeRange.upperBound - self.event.timeRange.lowerBound) / CGFloat(self.maxTime)
      * self.totalWidth
    let isActive =
      self.currentTime >= self.event.timeRange.lowerBound
      && self.currentTime <= self.event.timeRange.upperBound

    VStack(alignment: .leading, spacing: 4) {
      Text(self.event.title)
        .font(APGITypography.micro)
        .foregroundStyle(self.isSelected ? .white : .primary)
        .lineLimit(1)

      RoundedRectangle(cornerRadius: APGISpacing.sm)
        .fill(
          LinearGradient(
            colors: [
              self.event.category.color.opacity(isActive ? 1.0 : 0.7),
              self.event.category.color.opacity(isActive ? 0.8 : 0.5)
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: max(width, 40), height: 32)
        .overlay {
          if isActive {
            RoundedRectangle(cornerRadius: APGISpacing.sm)
              .stroke(self.event.category.color, lineWidth: 2)
              .opacity(0.5)
              .scaleEffect(1.1)
          }
        }
        .shadow(
          color: self.event.category.color.opacity(isActive ? 0.4 : 0.2),
          radius: isActive ? 8 : 4,
          y: 2
        )
    }
    .padding(.horizontal, APGISpacing.xs)
    .padding(.vertical, APGISpacing.xs)
    .background(self.isSelected ? self.event.category.color.opacity(0.35) : Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: APGISpacing.md))
    .offset(x: startX, y: 20)
    .scaleEffect(
      {
        if self.isSelected {
          return 1.05
        } else if self.isHovered {
          return 1.02
        } else {
          return 1.0
        }
      }()
    )
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: self.isSelected)
    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isActive)
    .onHover { hovering in
      self.isHovered = hovering
    }
  }
}

struct TimelineGrid: View {
  let maxTime: Int

  var body: some View {
    Canvas { context, size in
      let spacing = size.width / 5

      for i in 0...5 {
        let x = CGFloat(i) * spacing

        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: size.height))

        context.stroke(
          path,
          with: .color(.secondary.opacity(i == 0 || i == 5 ? 0.3 : 0.1)),
          lineWidth: i == 0 || i == 5 ? 1.5 : 1
        )
      }
    }
  }
}

struct PhaseRegions: View {
  let maxTime: Int

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        PhaseRegion(
          color: .apgiBlue,
          width: geometry.size.width * 0.3,
          label: "Pre-conscious"
        )
        PhaseRegion(
          color: .apgiOrange,
          width: geometry.size.width * 0.3,
          label: "Transition"
        )
        PhaseRegion(
          color: .apgiGreen,
          width: geometry.size.width * 0.4,
          label: "Conscious"
        )
      }
    }
  }
}

struct PhaseRegion: View {
  let color: Color
  let width: CGFloat
  let label: String

  var body: some View {
    VStack {
      Text(self.label)
        .font(APGITypography.micro)
        .foregroundStyle(self.color)
        .opacity(0.7)

      Spacer()
    }
    .frame(width: self.width)
    .background(self.color.opacity(0.1))
  }
}

struct PlayheadIndicator: View {
  let currentTime: Int
  let maxTime: Int

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let position = CGFloat(currentTime) / CGFloat(self.maxTime) * width

      ZStack(alignment: .top) {
        Rectangle()
          .fill(Color.apgiRed)
          .frame(width: 2)

        Circle()
          .fill(Color.apgiRed)
          .frame(width: 12, height: 12)
          .offset(y: -6)
      }
      .offset(x: position)
      .animation(.interactiveSpring(), value: self.currentTime)
    }
  }
}

struct EventProgressBar: View {
  let currentTime: Int
  let event: TimelineEvent

  private var progress: Double {
    let duration = Double(event.timeRange.upperBound - self.event.timeRange.lowerBound)
    let elapsed = Double(currentTime - self.event.timeRange.lowerBound)
    return min(max(elapsed / max(1, duration), 0), 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: APGISpacing.xs) {
      HStack {
        Text("Progress")
          .font(APGITypography.micro)
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(Int(self.progress * 100))%")
          .font(APGITypography.micro)
          .foregroundStyle(.primary)
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(self.event.category.color.opacity(0.2))

          RoundedRectangle(cornerRadius: 4)
            .fill(self.event.category.color)
            .frame(width: geometry.size.width * self.progress)
            .animation(.linear(duration: 0.1), value: self.progress)
        }
      }
      .frame(height: 8)
    }
  }
}

struct TimelineEvent: Identifiable {
  let id = UUID()
  let title: String
  let description: String
  let timeRange: ClosedRange<Int>
  let category: TimelineEventCategory
  let phase: TimelinePhase

  static let sampleEvents: [TimelineEvent] = [
    TimelineEvent(
      title: "Sensory Input",
      description:
        "Initial sensory signals arrive and begin processing in primary sensory cortices",
      timeRange: 0...50,
      category: .sensory,
      phase: .preconscious
    ),
    TimelineEvent(
      title: "Prediction Error",
      description: "Hierarchical processing detects mismatch between predictions and sensory input",
      timeRange: 50...150,
      category: .processing,
      phase: .preconscious
    ),
    TimelineEvent(
      title: "Precision Weighting",
      description: "Context-dependent precision weights Πᵢ(M,c,a) modulate error signals",
      timeRange: 100...200,
      category: .computation,
      phase: .transition
    ),
    TimelineEvent(
      title: "Surprise Accumulation",
      description: "Weighted prediction errors accumulate as surprise Sₜ approaches threshold θₜ",
      timeRange: 150...300,
      category: .computation,
      phase: .transition
    ),
    TimelineEvent(
      title: "Threshold Crossing",
      description: "Surprise exceeds adaptive threshold, triggering ignition dynamics",
      timeRange: 280...320,
      category: .ignition,
      phase: .transition
    ),
    TimelineEvent(
      title: "Global Ignition",
      description: "Widespread broadcast to frontoparietal networks - content enters consciousness",
      timeRange: 300...500,
      category: .broadcast,
      phase: .conscious
    )
  ]
}

enum TimelineEventCategory {
  case sensory, processing, computation, ignition, broadcast

  var color: Color {
    switch self {
    case .sensory: return .apgiBlue
    case .processing: return .apgiPurple
    case .computation: return .apgiOrange
    case .ignition: return .apgiRed
    case .broadcast: return .apgiGreen
    }
  }
}

enum TimelinePhase: String {
  case preconscious = "Pre-conscious"
  case transition = "Transition"
  case conscious = "Conscious"

  var color: Color {
    switch self {
    case .preconscious: return .apgiBlue
    case .transition: return .apgiOrange
    case .conscious: return .apgiGreen
    }
  }
}

#Preview {
  EnhancedInteractiveTimeline()
    .frame(height: 600)
}
