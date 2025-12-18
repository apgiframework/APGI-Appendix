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

            if !BrainRegionsSceneLoader.canLoadScene {
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

    private static let cachedScene: SCNScene? = {
        for candidate in assetCandidates {
            if let url = Bundle.main.url(forResource: candidate, withExtension: nil) {
                if let scene = try? SCNScene(url: url, options: nil) {
                    return scene
                }
            }
        }

        if let scene = SCNScene(named: "BrainRegions") {
            return scene
        }

        return nil
    }()

    private static let placeholderScene: SCNScene = {
        let scene = SCNScene()

        let hull = SCNSphere(radius: 1.45)
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = NSColor.systemGray.withAlphaComponent(0.16)
        hullMaterial.lightingModel = .physicallyBased
        hullMaterial.isDoubleSided = true
        hull.materials = [hullMaterial]

        let hullNode = SCNNode(geometry: hull)
        hullNode.scale = SCNVector3(1.25, 0.95, 1.05)
        scene.rootNode.addChildNode(hullNode)

        let locations: [BrainRegion: SCNVector3] = [
            .anteriorInsula: SCNVector3(-0.65, 0.10, 0.85),
            .anteriorCingulate: SCNVector3(-0.10, 0.55, 0.95),
            .thalamicReticularNucleus: SCNVector3(0.10, -0.05, 0.25),
            .sensoryCortex: SCNVector3(0.85, 0.15, 0.55),
            .basalForebrain: SCNVector3(0.20, -0.45, 0.55),
            .rapheNuclei: SCNVector3(0.00, -0.25, -0.15),
            .prefrontalCortex: SCNVector3(0.35, 0.75, 0.75),
            .striatum: SCNVector3(0.65, -0.05, 0.35)
        ]

        for (region, position) in locations {
            let marker = SCNSphere(radius: 0.18)
            let material = SCNMaterial()
            material.diffuse.contents = NSColor.systemTeal.withAlphaComponent(0.55)
            material.lightingModel = .physicallyBased
            marker.materials = [material]

            let node = SCNNode(geometry: marker)
            node.name = region.rawValue
            node.position = position
            scene.rootNode.addChildNode(node)
        }

        return scene
    }()

    static var canLoadScene: Bool {
        true
    }

    static func loadScene() -> SCNScene? {
        cachedScene ?? placeholderScene
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
        view.antialiasingMode = .multisampling4X

        if let scene = BrainRegionsSceneLoader.loadScene() {
            view.scene = scene
            context.coordinator.captureBaseMaterials(from: scene)
            context.coordinator.configureSceneIfNeeded(scene, in: view)
            context.coordinator.applyHighlight(highlighted, in: scene)
        }

        return view
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene else {
            if let scene = BrainRegionsSceneLoader.loadScene() {
                nsView.scene = scene
                context.coordinator.captureBaseMaterials(from: scene)
                context.coordinator.configureSceneIfNeeded(scene, in: nsView)
                context.coordinator.applyHighlight(highlighted, in: scene)
            }
            return
        }

        context.coordinator.configureSceneIfNeeded(scene, in: nsView)
        context.coordinator.applyHighlight(highlighted, in: scene)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var baseMaterialsByNodeName: [String: [SCNMaterial]] = [:]
        private var didConfigureScene = false

        func captureBaseMaterials(from scene: SCNScene) {
            guard baseMaterialsByNodeName.isEmpty else { return }

            scene.rootNode.enumerateChildNodes { node, _ in
                guard let name = node.name, let materials = node.geometry?.materials else {
                    return
                }
                baseMaterialsByNodeName[name] = materials.map { $0.copy() as? SCNMaterial ?? $0 }
            }
        }

        func configureSceneIfNeeded(_ scene: SCNScene, in view: SCNView) {
            guard !didConfigureScene else { return }

            if let cameraNode = scene.rootNode.enumerateHierarchyFirst(where: { $0.camera != nil }) {
                view.pointOfView = cameraNode
            } else {
                let (center, radius) = scene.rootNode.approximateBounds()
                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.camera?.zNear = max(0.01, Double(radius) * 0.01)
                cameraNode.camera?.zFar = max(1000, Double(radius) * 20)
                let cameraDistance = max(2.5 as CGFloat, radius * (2.2 as CGFloat))
                cameraNode.position = SCNVector3(center.x, center.y, center.z + cameraDistance)
                cameraNode.look(at: center)
                scene.rootNode.addChildNode(cameraNode)
                view.pointOfView = cameraNode
            }

            if scene.rootNode.enumerateHierarchyFirst(where: { $0.light != nil }) == nil {
                let (center, radius) = scene.rootNode.approximateBounds()

                let key = SCNNode()
                key.light = SCNLight()
                key.light?.type = .omni
                key.light?.intensity = 900
                let keyPos = SCNVector3(center.x + radius, center.y + radius, center.z + radius)
                key.position = keyPos
                scene.rootNode.addChildNode(key)

                let fill = SCNNode()
                fill.light = SCNLight()
                fill.light?.type = .omni
                fill.light?.intensity = 450
                let fillPos = SCNVector3(center.x - radius, center.y, center.z + radius)
                fill.position = fillPos
                scene.rootNode.addChildNode(fill)

                let ambient = SCNNode()
                ambient.light = SCNLight()
                ambient.light?.type = .ambient
                ambient.light?.intensity = 250
                scene.rootNode.addChildNode(ambient)
            }

            didConfigureScene = true
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

private extension SCNNode {
    func enumerateHierarchyFirst(where predicate: (SCNNode) -> Bool) -> SCNNode? {
        if predicate(self) { return self }
        for child in childNodes {
            if let found = child.enumerateHierarchyFirst(where: predicate) {
                return found
            }
        }
        return nil
    }

    func approximateBounds() -> (center: SCNVector3, radius: CGFloat) {
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var minZ = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        var maxZ = -CGFloat.greatestFiniteMagnitude
        var found = false

        enumerateHierarchy { node, _ in
            guard let geometry = node.geometry else { return }
            let localMin = geometry.boundingBox.min
            let localMax = geometry.boundingBox.max

            let corners = [
                SCNVector3(localMin.x, localMin.y, localMin.z),
                SCNVector3(localMin.x, localMin.y, localMax.z),
                SCNVector3(localMin.x, localMax.y, localMin.z),
                SCNVector3(localMin.x, localMax.y, localMax.z),
                SCNVector3(localMax.x, localMin.y, localMin.z),
                SCNVector3(localMax.x, localMin.y, localMax.z),
                SCNVector3(localMax.x, localMax.y, localMin.z),
                SCNVector3(localMax.x, localMax.y, localMax.z)
            ]

            for corner in corners {
                let world = node.convertPosition(corner, to: self)
                let wx = CGFloat(world.x)
                let wy = CGFloat(world.y)
                let wz = CGFloat(world.z)

                minX = min(minX, wx)
                minY = min(minY, wy)
                minZ = min(minZ, wz)
                maxX = max(maxX, wx)
                maxY = max(maxY, wy)
                maxZ = max(maxZ, wz)
                found = true
            }
        }

        if !found {
            return (SCNVector3(0, 0, 0), 1)
        }

        let cx = (minX + maxX) / 2
        let cy = (minY + maxY) / 2
        let cz = (minZ + maxZ) / 2

        let dx = maxX - minX
        let dy = maxY - minY
        let dz = maxZ - minZ
        let distSq = (dx * dx) + (dy * dy) + (dz * dz)
        let diameter = sqrt(distSq)
        let radius = max(0.1 as CGFloat, diameter / 2)

        let center = SCNVector3(x: cx, y: cy, z: cz)
        return (center, radius)
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
    @GestureState private var gestureZoom: CGFloat = 1.0
    @State private var pan: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let offset = CGSize(width: pan.width + dragOffset.width, height: pan.height + dragOffset.height)
                let effectiveZoom = clampedZoom(zoom * gestureZoom)

                for node in nodes {
                    for connectionId in node.connections {
                        if let target = nodes.first(where: { $0.id == connectionId }) {
                            drawConnection(context, from: node, to: target, center: center, offset: offset, zoom: effectiveZoom)
                        }
                    }
                }

                for node in nodes {
                    drawNode(context, node: node, center: center, offset: offset, zoom: effectiveZoom, isSelected: node.id == selectedNode?.id)
                }
            }
            .onAppear {
                canvasSize = proxy.size
            }
            .onChange(of: proxy.size) {
                canvasSize = proxy.size
            }
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .simultaneousGesture(magnificationGesture)
        .simultaneousGesture(dragGesture)
        .simultaneousGesture(tapGesture)
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
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoom = clampedZoom(zoom * value)
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
                selectedNode = node(at: point, canvasSize: canvasSize)
            }
    }

    private func node(at point: CGPoint, canvasSize: CGSize) -> GraphNode? {
        let hitRadius: CGFloat = 18
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let offset = CGSize(width: pan.width, height: pan.height)
        let effectiveZoom = clampedZoom(zoom)

        return nodes.first(where: { node in
            let p = CGPoint(
                x: center.x + (node.position.x * effectiveZoom) + offset.width,
                y: center.y + (node.position.y * effectiveZoom) + offset.height
            )
            let dx = point.x - p.x
            let dy = point.y - p.y
            return (dx * dx + dy * dy) <= hitRadius * hitRadius
        })
    }

    private func drawConnection(_ context: GraphicsContext, from: GraphNode, to: GraphNode, center: CGPoint, offset: CGSize, zoom: CGFloat) {
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

    private func drawNode(_ context: GraphicsContext, node: GraphNode, center: CGPoint, offset: CGSize, zoom: CGFloat, isSelected: Bool) {
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

    private func clampedZoom(_ value: CGFloat) -> CGFloat {
        min(max(0.5, value), 2.5)
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
