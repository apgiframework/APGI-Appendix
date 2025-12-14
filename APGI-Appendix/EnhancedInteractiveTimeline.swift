import SwiftUI
import Combine

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
        self.timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack(spacing: APGISpacing.xl) {
            headerSection
            timelineSection
            timeMarkersSection

            if let event = selectedEvent {
                eventDetailsPanel(for: event)
            }
        }
        .padding(APGISpacing.xl)
        .onReceive(timer) { _ in
            updatePlayback()
        }
        .onAppear {
            selectedEvent = events.first
        }
    }

    private var headerSection: some View {
        VStack(spacing: APGISpacing.md) {
            HStack {
                Text("Ignition Timeline")
                    .font(APGITypography.titleLarge)
                    .fontWeight(.bold)

                Spacer()

                Toggle(isOn: $showPhaseIndicators) {
                    Label("Show Phases", systemImage: "square.3.layers.3d")
                        .font(APGITypography.labelMedium)
                }
                .toggleStyle(.button)
            }

            PlaybackControls(
                isPlaying: $isPlaying,
                currentTime: $currentTime,
                playbackSpeed: $playbackSpeed,
                maxTime: maxTime,
                onReset: reset
            )
        }
    }

    private var timelineSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                TimelineGrid(maxTime: maxTime)

                if showPhaseIndicators {
                    PhaseRegions(maxTime: maxTime)
                        .opacity(0.15)
                        .transition(.opacity)
                }

                ForEach(events) { event in
                    EventBlock(
                        event: event,
                        isSelected: selectedEvent?.id == event.id,
                        isHovered: hoveredEvent?.id == event.id,
                        currentTime: currentTime,
                        totalWidth: geometry.size.width,
                        maxTime: maxTime
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedEvent = event
                        }
                    }
                    .onHover { hovering in
                        hoveredEvent = hovering ? event : nil
                    }
                }

                PlayheadIndicator(
                    currentTime: currentTime,
                    maxTime: maxTime
                )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            isPlaying = false
                            let ratio = min(max(0, value.location.x / max(1, geometry.size.width)), 1)
                            currentTime = Int(ratio * Double(maxTime))
                        }
                    }
            )
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: APGIRadius.lg)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: APGIRadius.lg)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
        }
    }

    private var timeMarkersSection: some View {
        HStack(spacing: 0) {
            ForEach([0, 100, 200, 300, 400, 500], id: \.self) { time in
                Text("\(time)ms")
                    .font(APGITypography.labelSmall)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: time == 0 ? .leading : (time == maxTime ? .trailing : .center)
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
                    .font(APGITypography.titleMedium)
                    .fontWeight(.semibold)

                Text("(\(event.timeRange.lowerBound)–\(event.timeRange.upperBound)ms)")
                    .font(APGITypography.bodySmall)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(event.phase.rawValue)
                    .font(APGITypography.labelSmall)
                    .padding(.horizontal, APGISpacing.sm)
                    .padding(.vertical, APGISpacing.xs)
                    .background(event.phase.color.opacity(0.2))
                    .foregroundStyle(event.phase.color)
                    .clipShape(Capsule())
            }

            GlossaryHighlightedText(text: event.description)
                .font(APGITypography.bodyMedium)
                .foregroundStyle(.secondary)
                .lineSpacing(4)

            if currentTime >= event.timeRange.lowerBound && currentTime <= event.timeRange.upperBound {
                EventProgressBar(
                    currentTime: currentTime,
                    event: event
                )
            }
        }
        .padding(APGISpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: APGIRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: APGIRadius.lg)
                .strokeBorder(event.category.color.opacity(0.3), lineWidth: 1.5)
        }
        .shadow(color: event.category.color.opacity(0.2), radius: 8, y: 4)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private func updatePlayback() {
        guard isPlaying else { return }
        withAnimation(.linear(duration: tickInterval)) {
            if currentTime < maxTime {
                currentTime = min(maxTime, currentTime + Int(playbackSpeed * 10))
            } else {
                isPlaying = false
                currentTime = 0
            }
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentTime = 0
            isPlaying = false
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
            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .help(isPlaying ? "Pause" : "Play")

            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Reset")

            Text("\(currentTime)ms")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .trailing)

            Spacer()

            HStack(spacing: APGISpacing.sm) {
                Text("Speed:")
                    .font(APGITypography.labelMedium)
                    .foregroundStyle(.secondary)

                ForEach([0.5, 1.0, 2.0], id: \.self) { speed in
                    Button(action: { playbackSpeed = speed }) {
                        Text("\(speed, specifier: "%.1f")x")
                            .font(APGITypography.labelMedium)
                            .foregroundStyle(playbackSpeed == speed ? .white : .primary)
                            .padding(.horizontal, APGISpacing.sm)
                            .padding(.vertical, APGISpacing.xs)
                            .background(
                                playbackSpeed == speed
                                    ? Color.accentColor
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
        let startX = CGFloat(event.timeRange.lowerBound) / CGFloat(maxTime) * totalWidth
        let width = CGFloat(event.timeRange.upperBound - event.timeRange.lowerBound) / CGFloat(maxTime) * totalWidth
        let isActive = currentTime >= event.timeRange.lowerBound && currentTime <= event.timeRange.upperBound

        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(APGITypography.labelSmall)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            RoundedRectangle(cornerRadius: APGIRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [
                            event.category.color.opacity(isActive ? 1.0 : 0.7),
                            event.category.color.opacity(isActive ? 0.8 : 0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(width, 40), height: 36)
                .overlay {
                    if isActive {
                        RoundedRectangle(cornerRadius: APGIRadius.sm)
                            .stroke(event.category.color, lineWidth: 2)
                            .opacity(0.5)
                            .scaleEffect(1.1)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isActive
                            )
                    }
                }
                .shadow(
                    color: event.category.color.opacity(isActive ? 0.4 : 0.2),
                    radius: isActive ? 8 : 4,
                    y: 2
                )
        }
        .padding(.horizontal, APGISpacing.xs)
        .padding(.vertical, APGISpacing.xs)
        .background(isSelected ? event.category.color.opacity(0.35) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: APGIRadius.md))
        .offset(x: startX, y: 20)
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isActive)
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
            Text(label)
                .font(APGITypography.labelSmall)
                .foregroundStyle(color)
                .opacity(0.7)

            Spacer()
        }
        .frame(width: width)
        .background(color.opacity(0.1))
    }
}

struct PlayheadIndicator: View {
    let currentTime: Int
    let maxTime: Int

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let position = CGFloat(currentTime) / CGFloat(maxTime) * width

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
            .animation(.interactiveSpring(), value: currentTime)
        }
    }
}

struct EventProgressBar: View {
    let currentTime: Int
    let event: TimelineEvent

    private var progress: Double {
        let duration = Double(event.timeRange.upperBound - event.timeRange.lowerBound)
        let elapsed = Double(currentTime - event.timeRange.lowerBound)
        return min(max(elapsed / max(1, duration), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: APGISpacing.xs) {
            HStack {
                Text("Progress")
                    .font(APGITypography.labelSmall)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(APGITypography.labelSmall)
                    .foregroundStyle(.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.category.color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.category.color)
                        .frame(width: geometry.size.width * progress)
                        .animation(.linear(duration: 0.1), value: progress)
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
            description: "Initial sensory signals arrive and begin processing in primary sensory cortices",
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
