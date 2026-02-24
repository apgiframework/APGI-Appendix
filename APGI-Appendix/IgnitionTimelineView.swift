import Combine
import SwiftUI

struct InteractiveTimelineView: View {
    struct TimelineEvent: Identifiable {
        let id = UUID()
        let timeRange: ClosedRange<Int>
        let title: String
        let description: String
        let category: EventCategory

        enum EventCategory {
            case trigger
            case amplification
            case stabilization
            case broadcast
            case consolidation
            case memory
            case refractory

            var color: Color {
                switch self {
                case .trigger: return .blue
                case .amplification: return .purple
                case .stabilization: return .green
                case .broadcast: return .orange
                case .consolidation: return .red
                case .memory: return .pink
                case .refractory: return .gray
                }
            }
        }

        var durationMs: Int {
            max(0, self.timeRange.upperBound - self.timeRange.lowerBound)
        }
    }

    private let maxTime: Int = 500
    private let tickMs: Int = 5
    private let tickInterval: TimeInterval = 0.05

    private let events: [TimelineEvent] = [
        .init(
            timeRange: 0 ... 50,
            title: "Trigger",
            description: "Matrix thalamus (pulvinar/MD) projects to L1 apical tufts; neuromodulatory gain disinhibits thalamus, initiating apical integration.",
            category: .trigger
        ),
        .init(
            timeRange: 50 ... 100,
            title: "Amplification",
            description: "NMDA-mediated Ca²⁺ spikes in L5 apical dendrites; somatic bursting begins if coincident with basal input; competition intensifies.",
            category: .amplification
        ),
        .init(
            timeRange: 100 ... 150,
            title: "Local Stabilization",
            description: "L5 burst output propagates to L2/3; recurrent excitation begins; local gamma (30–80 Hz) rises and horizontal integration starts.",
            category: .stabilization
        ),
        .init(
            timeRange: 150 ... 200,
            title: "Salience Broadcast",
            description: "Long-range gamma phase-locking initiates across frontal/parietal/insular regions; P3a (~200 ms) reflects salience detection.",
            category: .broadcast
        ),
        .init(
            timeRange: 200 ... 250,
            title: "Consolidation",
            description: "Sustained high-firing attractor consolidates; TRN re-engagement begins; pupillary dilation peaks (LC–NE burst) as metastability emerges.",
            category: .consolidation
        ),
        .init(
            timeRange: 250 ... 300,
            title: "Ignition Confirmation",
            description: "P3b (~300 ms) peaks; peak gamma synchrony across frontoparietal/temporal regions; global availability becomes reportable and memory-encodable.",
            category: .consolidation
        ),
        .init(
            timeRange: 300 ... 350,
            title: "Memory & Report",
            description: "Hippocampal sharp-wave ripples begin encoding; language areas engage if verbal report is required.",
            category: .memory
        ),
        .init(
            timeRange: 350 ... 400,
            title: "Refractory Initiation",
            description: "Threshold rises (post-ignition refractoriness); SOM⁺ interneurons enforce feedback inhibition, preparing for attentional blink.",
            category: .refractory
        ),
        .init(
            timeRange: 400 ... 450,
            title: "Stabilization / Decay",
            description: "Frontoparietal firing remains elevated but can decay without maintenance; alpha rebounds and inhibitory tone reinstates.",
            category: .stabilization
        ),
        .init(
            timeRange: 450 ... 500,
            title: "Temporal Integration",
            description: "Activity returns toward baseline in non-maintained trials; theta-phase binding may group ignition into a ~3-second narrative window.",
            category: .memory
        ),
    ]

    @State private var selectedEventID: TimelineEvent.ID?
    @State private var currentTime: Int = 0
    @State private var isPlaying: Bool = false

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init() {
        self.timer = Timer.publish(every: self.tickInterval, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Ignition Timeline")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        self.isPlaying.toggle()
                    } label: {
                        Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .accessibilityLabel(self.isPlaying ? "Pause timeline animation" : "Play timeline animation")
                    .accessibilityHint("Controls the automatic progression through the ignition timeline")

                    Button {
                        self.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset timeline")
                    .accessibilityHint("Returns the timeline to the beginning")
                }
                .buttonStyle(.bordered)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 120)
                        .accessibilityLabel("Ignition timeline scrubber")
                        .accessibilityHint("Drag to scrub through the timeline or use arrow keys to navigate")
                        .accessibilityValue("\(self.currentTime) milliseconds")

                    ForEach(self.events) { event in
                        let startX = CGFloat(event.timeRange.lowerBound) / CGFloat(self.maxTime) * geometry.size.width
                        let width = CGFloat(event.durationMs) / CGFloat(self.maxTime) * geometry.size.width
                        let isSelected = selectedEventID == event.id

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("\(event.timeRange.lowerBound)–\(event.timeRange.upperBound)ms")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(8)
                        .frame(width: max(44, width), height: 100, alignment: .topLeading)
                        .background(event.category.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSelected ? Color.white : Color.clear, lineWidth: 2)
                        }
                        .offset(x: startX, y: 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEventID = event.id
                        }
                        .accessibilityLabel("\(event.title), \(event.timeRange.lowerBound) to \(event.timeRange.upperBound) milliseconds")
                        .accessibilityHint("Tap to view details for this ignition phase")
                        .accessibilityAddTraits(.isButton)
                    }

                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 120)
                        .offset(x: CGFloat(self.currentTime) / CGFloat(self.maxTime) * geometry.size.width)
                        .accessibilityHidden(true) // The timeline itself provides the value
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            self.isPlaying = false
                            let ratio = min(max(0, value.location.x / max(1, geometry.size.width)), 1)
                            self.currentTime = Int((Double(ratio) * Double(self.maxTime)).rounded())
                        }
                )
                .accessibilityAction(named: "Move to previous event") {
                    if let currentEvent = events.first(where: { $0.timeRange.contains(currentTime) }),
                       let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
                       currentIndex > 0
                    {
                        let previousEvent = self.events[currentIndex - 1]
                        self.currentTime = previousEvent.timeRange.lowerBound
                        selectedEventID = previousEvent.id
                    }
                }
                .accessibilityAction(named: "Move to next event") {
                    if let currentEvent = events.first(where: { $0.timeRange.contains(currentTime) }),
                       let currentIndex = events.firstIndex(where: { $0.id == currentEvent.id }),
                       currentIndex < events.count - 1
                    {
                        let nextEvent = self.events[currentIndex + 1]
                        self.currentTime = nextEvent.timeRange.lowerBound
                        selectedEventID = nextEvent.id
                    }
                }
            }
            .frame(height: 120)
            .onReceive(self.timer) { _ in
                guard self.isPlaying else { return }
                if self.currentTime < self.maxTime {
                    self.currentTime = min(self.maxTime, self.currentTime + self.tickMs)
                }
                else {
                    self.isPlaying = false
                    self.currentTime = 0
                }
            }

            HStack {
                ForEach([0, 100, 200, 300, 400, 500], id: \.self) { time in
                    Text("\(time)ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(
                            maxWidth: .infinity,
                            alignment: time == 0 ? .leading : (time == self.maxTime ? .trailing : .center)
                        )
                }
            }

            if let selectedEventID,
               let event = events.first(where: { $0.id == selectedEventID })
            {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(event.category.color)
                            .frame(width: 12, height: 12)

                        Text(event.title)
                            .font(.headline)

                        Text("(\(event.timeRange.lowerBound)–\(event.timeRange.upperBound)ms)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    GlossaryHighlightedText(text: event.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .onAppear {
            if self.selectedEventID == nil {
                self.selectedEventID = self.events.first?.id
            }
        }
    }

    private func reset() {
        self.currentTime = 0
        self.isPlaying = false
    }
}

struct IgnitionTimelineView: View {
    var body: some View {
        ScrollView {
            EnhancedInteractiveTimeline()
        }
    }
}

#Preview {
    IgnitionTimelineView()
}
