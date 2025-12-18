import SwiftUI
import SceneKit

struct InteractiveVisualizationsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Interactive Visualizations")
                    .font(.title.bold())
                    .padding(.horizontal)

                InteractiveNeuralVisualization()
                    .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                Text("Network Graph")
                    .font(.title2.bold())
                    .padding(.horizontal)

                NetworkGraphView()
                    .frame(height: 520)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

enum Neuromodulator: String, CaseIterable, Identifiable {
    case norepinephrine
    case acetylcholine
    case serotonin
    case dopamine

    var id: String { rawValue }

    var name: String {
        switch self {
        case .norepinephrine: return "Norepinephrine (NE)"
        case .acetylcholine: return "Acetylcholine (ACh)"
        case .serotonin: return "Serotonin (5-HT)"
        case .dopamine: return "Dopamine (DA)"
        }
    }

    var affectedRegions: [BrainRegion] {
        switch self {
        case .norepinephrine:
            return [.anteriorInsula, .anteriorCingulate, .thalamicReticularNucleus]
        case .acetylcholine:
            return [.sensoryCortex, .basalForebrain]
        case .serotonin:
            return [.prefrontalCortex, .rapheNuclei]
        case .dopamine:
            return [.prefrontalCortex, .striatum]
        }
    }

    var parameters: [ParameterValue] {
        switch self {
        case .norepinephrine:
            return [
                ParameterValue(name: "κ_NE", min: 0.25, max: 0.35, unit: ""),
                ParameterValue(name: "Πᵢ gain", min: 1.0, max: 5.0, unit: "×")
            ]
        case .acetylcholine:
            return [
                ParameterValue(name: "κ_ACh", min: 0.10, max: 0.20, unit: ""),
                ParameterValue(name: "Πₑ gain", min: 1.0, max: 3.0, unit: "×")
            ]
        case .serotonin:
            return [
                ParameterValue(name: "κ_5-HT", min: 0.35, max: 0.50, unit: ""),
                ParameterValue(name: "δ refractoriness", min: 1.0, max: 2.0, unit: "×")
            ]
        case .dopamine:
            return [
                ParameterValue(name: "θₜ tonic", min: 0.8, max: 1.3, unit: "×"),
                ParameterValue(name: "reward salience", min: 0.0, max: 1.0, unit: "")
            ]
        }
    }
}

enum BrainRegion: String, CaseIterable, Hashable, Identifiable {
    case anteriorInsula
    case anteriorCingulate
    case thalamicReticularNucleus
    case sensoryCortex
    case basalForebrain
    case rapheNuclei
    case prefrontalCortex
    case striatum

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anteriorInsula: return "AI"
        case .anteriorCingulate: return "ACC"
        case .thalamicReticularNucleus: return "TRN"
        case .sensoryCortex: return "Sensory"
        case .basalForebrain: return "BF"
        case .rapheNuclei: return "Raphe"
        case .prefrontalCortex: return "PFC"
        case .striatum: return "Striatum"
        }
    }
}

struct ParameterValue: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let min: Double
    let max: Double
    let unit: String

    func value(progress: Double) -> Double {
        min + (max - min) * progress
    }
}

struct InteractiveNeuralVisualization: View {
    @State private var selectedNeuromodulator: Neuromodulator?
    @State private var animationProgress: Double = 0
    @State private var showingParameters = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrainModelView(highlighted: selectedNeuromodulator?.affectedRegions ?? [])
                .frame(height: 400)
                .overlay(alignment: .topLeading) {
                    RegionLabels(highlighted: selectedNeuromodulator?.affectedRegions ?? [])
                        .padding(12)
                }

            HStack(spacing: 14) {
                Picker("Neuromodulator", selection: $selectedNeuromodulator) {
                    Text("None").tag(nil as Neuromodulator?)
                    ForEach(Neuromodulator.allCases) { nm in
                        Text(nm.name).tag(nm as Neuromodulator?)
                    }
                }
                .frame(maxWidth: 320)

                Button {
                    animateEffect()
                } label: {
                    Label("Animate Effect", systemImage: "play.fill")
                }

                Slider(value: $animationProgress, in: 0...1)
                    .frame(width: 200)

                Toggle("Parameters", isOn: $showingParameters)
                    .toggleStyle(.switch)

                Spacer()
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if showingParameters, let nm = selectedNeuromodulator {
                ParameterDashboard(neuromodulator: nm, progress: animationProgress)
            }
        }
    }

    private func animateEffect() {
        withAnimation(.easeInOut(duration: 1.4)) {
            animationProgress = animationProgress < 1 ? 1 : 0
        }
    }
}

private struct BrainModelView: View {
    let highlighted: [BrainRegion]

    var body: some View {
        ZStack {
            BrainRegionsSceneView(highlighted: highlighted)

            if !BrainRegionsSceneLoader.hasBundledAsset {
                BrainModelFallbackView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct BrainModelFallbackView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("3D model unavailable")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum BrainRegionsSceneLoader {
    static let assetCandidates: [String] = [
        "BrainRegions.scn",
        "BrainRegions.usdz",
        "BrainRegions.dae"
    ]

    static var hasBundledAsset: Bool {
        assetCandidates.contains(where: { Bundle.main.url(forResource: $0, withExtension: nil) != nil })
    }

    static func loadScene() -> SCNScene? {
        for candidate in assetCandidates {
            if let url = Bundle.main.url(forResource: candidate, withExtension: nil) {
                return try? SCNScene(url: url, options: nil)
            }
        }

        if let scene = SCNScene(named: "BrainRegions") {
            return scene
        }

        return nil
    }
}

private struct BrainRegionsSceneView: NSViewRepresentable {
    let highlighted: [BrainRegion]

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.rendersContinuously = true

        if let scene = BrainRegionsSceneLoader.loadScene() {
            view.scene = scene
            context.coordinator.captureBaseMaterials(from: scene)
            context.coordinator.applyHighlight(highlighted, in: scene)
        }

        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene else {
            if let scene = BrainRegionsSceneLoader.loadScene() {
                nsView.scene = scene
                context.coordinator.captureBaseMaterials(from: scene)
                context.coordinator.applyHighlight(highlighted, in: scene)
            }
            return
        }

        context.coordinator.applyHighlight(highlighted, in: scene)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var baseMaterialsByNodeName: [String: [SCNMaterial]] = [:]

        func captureBaseMaterials(from scene: SCNScene) {
            guard baseMaterialsByNodeName.isEmpty else { return }

            scene.rootNode.enumerateChildNodes { node, _ in
                guard let name = node.name, let materials = node.geometry?.materials else {
                    return
                }
                baseMaterialsByNodeName[name] = materials.map { $0.copy() as? SCNMaterial ?? $0 }
            }
        }

        func applyHighlight(_ regions: [BrainRegion], in scene: SCNScene) {
            let highlightNames = Set(regions.map { $0.nodeName })

            scene.rootNode.enumerateChildNodes { node, _ in
                guard let name = node.name, let geometry = node.geometry else {
                    return
                }

                if highlightNames.contains(name) {
                    geometry.materials = geometry.materials.map { material in
                        let updated = material.copy() as? SCNMaterial ?? material
                        updated.emission.contents = NSColor.systemYellow
                        updated.emission.intensity = 0.85
                        updated.lightingModel = .physicallyBased
                        return updated
                    }
                } else if let base = baseMaterialsByNodeName[name] {
                    geometry.materials = base.map { $0.copy() as? SCNMaterial ?? $0 }
                }
            }
        }
    }
}

private extension BrainRegion {
    var nodeName: String {
        rawValue
    }
}

struct RegionLabels: View {
    let highlighted: [BrainRegion]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(BrainRegion.allCases) { region in
                HStack(spacing: 8) {
                    Circle()
                        .fill(highlighted.contains(region) ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 8, height: 8)

                    Text(region.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(highlighted.contains(region) ? .primary : .secondary)
                }
            }
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ParameterDashboard: View {
    let neuromodulator: Neuromodulator
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Parameters")
                .font(.headline)

            ForEach(neuromodulator.parameters) { p in
                HStack {
                    Text(p.name)
                        .font(.subheadline)
                    Spacer()
                    Text(formatted(p.value(progress: progress), unit: p.unit))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatted(_ value: Double, unit: String) -> String {
        let v = (value * 100).rounded() / 100
        if unit.isEmpty {
            return "\(v)"
        }
        return "\(v)\(unit)"
    }
}

struct GraphNode: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var position: CGPoint
    var strength: Double
    var connections: [UUID]
}

struct NetworkGraphView: View {
    @State private var nodes: [GraphNode] = NetworkGraphView.makeDefaultNodes()
    @State private var selectedNode: GraphNode?
    @State private var zoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let offset = CGSize(width: pan.width + dragOffset.width, height: pan.height + dragOffset.height)

            for node in nodes {
                for connectionId in node.connections {
                    if let target = nodes.first(where: { $0.id == connectionId }) {
                        drawConnection(context, from: node, to: target, center: center, offset: offset)
                    }
                }
            }

            for node in nodes {
                drawNode(context, node: node, center: center, offset: offset, isSelected: node.id == selectedNode?.id)
            }
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .gesture(magnificationGesture)
        .gesture(dragGesture)
        .gesture(tapGesture)
        .overlay(alignment: .topTrailing) {
            if let node = selectedNode {
                NodeDetailPopover(node: node)
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedNode)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                zoom = min(max(0.5, value), 2.5)
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                pan = CGSize(width: pan.width + value.translation.width, height: pan.height + value.translation.height)
            }
    }

    private var tapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                let point = value.location
                selectedNode = node(at: point, in: value)
            }
    }

    private func node(at point: CGPoint, in _: DragGesture.Value) -> GraphNode? {
        let hitRadius: CGFloat = 18
        let center = CGPoint(x: 0, y: 0)
        let offset = CGSize(width: pan.width, height: pan.height)

        return nodes.first(where: { node in
            let p = CGPoint(
                x: center.x + (node.position.x * zoom) + offset.width,
                y: center.y + (node.position.y * zoom) + offset.height
            )
            let dx = point.x - p.x
            let dy = point.y - p.y
            return (dx * dx + dy * dy) <= hitRadius * hitRadius
        })
    }

    private func drawConnection(_ context: GraphicsContext, from: GraphNode, to: GraphNode, center: CGPoint, offset: CGSize) {
        let start = CGPoint(
            x: center.x + (from.position.x * zoom) + offset.width,
            y: center.y + (from.position.y * zoom) + offset.height
        )
        let end = CGPoint(
            x: center.x + (to.position.x * zoom) + offset.width,
            y: center.y + (to.position.y * zoom) + offset.height
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        context.stroke(path, with: .color(.secondary.opacity(0.25)), lineWidth: 1)
    }

    private func drawNode(_ context: GraphicsContext, node: GraphNode, center: CGPoint, offset: CGSize, isSelected: Bool) {
        let p = CGPoint(
            x: center.x + (node.position.x * zoom) + offset.width,
            y: center.y + (node.position.y * zoom) + offset.height
        )

        let r: CGFloat = 10 + CGFloat(max(0, min(1, node.strength))) * 10
        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)

        context.fill(Path(ellipseIn: rect), with: .color(isSelected ? .accentColor : .primary.opacity(0.65)))

        let text = Text(node.title).font(.caption2.weight(.semibold)).foregroundStyle(.primary)
        context.draw(text, at: CGPoint(x: p.x, y: p.y - r - 10), anchor: .center)
    }

    private static func makeDefaultNodes() -> [GraphNode] {
        let a = GraphNode(title: "AI", position: CGPoint(x: -120, y: -40), strength: 0.8, connections: [])
        let b = GraphNode(title: "ACC", position: CGPoint(x: -40, y: -90), strength: 0.7, connections: [])
        let c = GraphNode(title: "PFC", position: CGPoint(x: 70, y: -60), strength: 0.9, connections: [])
        let d = GraphNode(title: "TRN", position: CGPoint(x: 20, y: 60), strength: 0.55, connections: [])
        let e = GraphNode(title: "Striatum", position: CGPoint(x: 120, y: 70), strength: 0.75, connections: [])

        let nodes = [a, b, c, d, e]
        let ids = nodes.map { $0.id }

        return [
            GraphNode(title: a.title, position: a.position, strength: a.strength, connections: [ids[1], ids[3]]),
            GraphNode(title: b.title, position: b.position, strength: b.strength, connections: [ids[0], ids[2]]),
            GraphNode(title: c.title, position: c.position, strength: c.strength, connections: [ids[1], ids[4]]),
            GraphNode(title: d.title, position: d.position, strength: d.strength, connections: [ids[0], ids[4]]),
            GraphNode(title: e.title, position: e.position, strength: e.strength, connections: [ids[2], ids[3]])
        ]
    }
}

struct NodeDetailPopover: View {
    let node: GraphNode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(node.title)
                .font(.headline)

            HStack {
                Text("Strength")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f", node.strength))
                    .font(.subheadline.monospacedDigit())
            }

            HStack {
                Text("Connections")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(node.connections.count)")
                    .font(.subheadline.monospacedDigit())
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    InteractiveVisualizationsView()
}
