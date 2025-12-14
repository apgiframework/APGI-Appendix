import SwiftUI
import Combine

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
            max(0, timeRange.upperBound - timeRange.lowerBound)
        }
    }

    private let maxTime: Int = 500
    private let tickMs: Int = 5
    private let tickInterval: TimeInterval = 0.05

    private let events: [TimelineEvent] = [
        .init(
            timeRange: 0...50,
            title: "Trigger",
            description: "Matrix thalamus (pulvinar/MD) projects to L1 apical tufts; neuromodulatory gain disinhibits thalamus, initiating apical integration.",
            category: .trigger
        ),
        .init(
            timeRange: 50...100,
            title: "Amplification",
            description: "NMDA-mediated Ca²⁺ spikes in L5 apical dendrites; somatic bursting begins if coincident with basal input; competition intensifies.",
            category: .amplification
        ),
        .init(
            timeRange: 100...150,
            title: "Local Stabilization",
            description: "L5 burst output propagates to L2/3; recurrent excitation begins; local gamma (30–80 Hz) rises and horizontal integration starts.",
            category: .stabilization
        ),
        .init(
            timeRange: 150...200,
            title: "Salience Broadcast",
            description: "Long-range gamma phase-locking initiates across frontal/parietal/insular regions; P3a (~200 ms) reflects salience detection.",
            category: .broadcast
        ),
        .init(
            timeRange: 200...250,
            title: "Consolidation",
            description: "Sustained high-firing attractor consolidates; TRN re-engagement begins; pupillary dilation peaks (LC–NE burst) as metastability emerges.",
            category: .consolidation
        ),
        .init(
            timeRange: 250...300,
            title: "Ignition Confirmation",
            description: "P3b (~300 ms) peaks; peak gamma synchrony across frontoparietal/temporal regions; global availability becomes reportable and memory-encodable.",
            category: .consolidation
        ),
        .init(
            timeRange: 300...350,
            title: "Memory & Report",
            description: "Hippocampal sharp-wave ripples begin encoding; language areas engage if verbal report is required.",
            category: .memory
        ),
        .init(
            timeRange: 350...400,
            title: "Refractory Initiation",
            description: "Threshold rises (post-ignition refractoriness); SOM⁺ interneurons enforce feedback inhibition, preparing for attentional blink.",
            category: .refractory
        ),
        .init(
            timeRange: 400...450,
            title: "Stabilization / Decay",
            description: "Frontoparietal firing remains elevated but can decay without maintenance; alpha rebounds and inhibitory tone reinstates.",
            category: .stabilization
        ),
        .init(
            timeRange: 450...500,
            title: "Temporal Integration",
            description: "Activity returns toward baseline in non-maintained trials; theta-phase binding may group ignition into a ~3-second narrative window.",
            category: .memory
        )
    ]

    @State private var selectedEventID: TimelineEvent.ID?
    @State private var currentTime: Int = 0
    @State private var isPlaying: Bool = false

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init() {
        self.timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Ignition Timeline")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    }

                    Button {
                        reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                .buttonStyle(.bordered)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 120)

                    ForEach(events) { event in
                        let startX = CGFloat(event.timeRange.lowerBound) / CGFloat(maxTime) * geometry.size.width
                        let width = CGFloat(event.durationMs) / CGFloat(maxTime) * geometry.size.width
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
                    }

                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 120)
                        .offset(x: CGFloat(currentTime) / CGFloat(maxTime) * geometry.size.width)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isPlaying = false
                            let ratio = min(max(0, value.location.x / max(1, geometry.size.width)), 1)
                            currentTime = Int((Double(ratio) * Double(maxTime)).rounded())
                        }
                )
            }
            .frame(height: 120)
            .onReceive(timer) { _ in
                guard isPlaying else { return }
                if currentTime < maxTime {
                    currentTime = min(maxTime, currentTime + tickMs)
                } else {
                    isPlaying = false
                    currentTime = 0
                }
            }

            HStack {
                ForEach([0, 100, 200, 300, 400, 500], id: \.self) { time in
                    Text("\(time)ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(
                            maxWidth: .infinity,
                            alignment: time == 0 ? .leading : (time == maxTime ? .trailing : .center)
                        )
                }
            }

            if let selectedEventID,
               let event = events.first(where: { $0.id == selectedEventID }) {
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
            if selectedEventID == nil {
                selectedEventID = events.first?.id
            }
        }
    }

    private func reset() {
        currentTime = 0
        isPlaying = false
    }
}

struct IgnitionTimelineView: View {
    var body: some View {
        ScrollView {
            InteractiveTimelineView()
        }
    }
}

#Preview {
    IgnitionTimelineView()
}
