import SwiftUI

// MARK: - Neural Circuit Diagram Components

/// Represents a node in the neural circuit
struct NeuralNode: Identifiable {
    let id = UUID()
    let label: String
    let abbreviation: String
    let description: String
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let nodeType: NodeType
    
    enum NodeType {
        case cortical      // Brain regions
        case subcortical   // Thalamus, brainstem
        case neuromodulator // NT systems
        case variable      // APGI variables
    }
}

/// Represents a connection between nodes
struct NeuralConnection: Identifiable {
    let id = UUID()
    let fromNode: UUID
    let toNode: UUID
    let connectionType: ConnectionType
    let label: String?
    let strength: Double // 0-1
    
    enum ConnectionType {
        case excitatory
        case inhibitory
        case modulatory
        case bidirectional
        
        var color: Color {
            switch self {
            case .excitatory: return .green
            case .inhibitory: return .red
            case .modulatory: return .purple
            case .bidirectional: return .blue
            }
        }
        
        var dashPattern: [CGFloat] {
            switch self {
            case .modulatory: return [5, 3]
            default: return []
            }
        }
    }
}

// MARK: - APGI Neural Circuit Diagram

struct APGINeuralCircuitDiagram: View {
    @State private var selectedNode: NeuralNode?
    @State private var hoveredNode: NeuralNode?
    @State private var animationPhase: Double = 0
    @State private var showLabels = true
    @State private var highlightedPathway: String?
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    // Define nodes
    private let nodes: [NeuralNode] = [
        // Cortical regions
        NeuralNode(
            label: "Posterior Parietal Cortex",
            abbreviation: "PPC",
            description: "L2/3 pyramidal cells accumulate precision-weighted prediction errors (Sₜ). Ramping activity reflects evidence accumulation through recurrent excitation.",
            position: CGPoint(x: 0.75, y: 0.25),
            color: .blue,
            size: 60,
            nodeType: .cortical
        ),
        NeuralNode(
            label: "Prefrontal Cortex L5",
            abbreviation: "PFC-L5",
            description: "Layer 5 pyramidal neurons with apical dendrites that integrate top-down predictions with bottom-up evidence. NMDA-spike threshold determines ignition.",
            position: CGPoint(x: 0.3, y: 0.3),
            color: .purple,
            size: 70,
            nodeType: .cortical
        ),
        NeuralNode(
            label: "Anterior Insula",
            abbreviation: "AI",
            description: "Hub for interoceptive prediction errors. Dense LC-NE projections amplify somatic signals during threat or high arousal states.",
            position: CGPoint(x: 0.5, y: 0.5),
            color: .orange,
            size: 55,
            nodeType: .cortical
        ),
        NeuralNode(
            label: "Anterior Cingulate",
            abbreviation: "ACC",
            description: "Integrates prediction errors across domains. Modulates ignition threshold based on conflict and uncertainty signals.",
            position: CGPoint(x: 0.35, y: 0.55),
            color: .red,
            size: 55,
            nodeType: .cortical
        ),
        
        // Subcortical
        NeuralNode(
            label: "Thalamic Reticular Nucleus",
            abbreviation: "TRN",
            description: "GABAergic inhibition of matrix thalamus. Sets baseline θ₀ through tonic inhibition. NE suppresses TRN, lowering threshold.",
            position: CGPoint(x: 0.5, y: 0.75),
            color: .gray,
            size: 50,
            nodeType: .subcortical
        ),
        NeuralNode(
            label: "Pulvinar/MD Thalamus",
            abbreviation: "Pulv",
            description: "Matrix thalamus provides coordinated drive to L1 apical tufts. Disinhibition triggers dendritic Ca²⁺ spikes.",
            position: CGPoint(x: 0.65, y: 0.7),
            color: .teal,
            size: 50,
            nodeType: .subcortical
        ),
        
        // Neuromodulators
        NeuralNode(
            label: "Locus Coeruleus (NE)",
            abbreviation: "LC",
            description: "Norepinephrine system. Phasic bursts lower θₜ and boost Πᵢ. Mediates urgency and threat responses.",
            position: CGPoint(x: 0.15, y: 0.7),
            color: .yellow,
            size: 45,
            nodeType: .neuromodulator
        ),
        NeuralNode(
            label: "Basal Forebrain (ACh)",
            abbreviation: "BF",
            description: "Acetylcholine system. Enhances Πₑ by sharpening sensory tuning. Signals expected uncertainty for learning.",
            position: CGPoint(x: 0.85, y: 0.6),
            color: .green,
            size: 45,
            nodeType: .neuromodulator
        ),
        
        // APGI Variables (shown as different shape)
        NeuralNode(
            label: "Surprise Signal",
            abbreviation: "Sₜ",
            description: "Accumulated precision-weighted prediction error. When Sₜ > θₜ, ignition occurs.",
            position: CGPoint(x: 0.9, y: 0.15),
            color: .cyan,
            size: 40,
            nodeType: .variable
        ),
        NeuralNode(
            label: "Ignition Threshold",
            abbreviation: "θₜ",
            description: "Dynamic barrier for conscious access. Modulated by homeostasis, refractoriness, and urgency.",
            position: CGPoint(x: 0.1, y: 0.4),
            color: .pink,
            size: 40,
            nodeType: .variable
        )
    ]
    
    // Define connections
    private var connections: [NeuralConnection] {
        guard nodes.count >= 10 else { return [] }
        
        return [
            // PPC → PFC-L5 (evidence)
            NeuralConnection(
                fromNode: nodes[0].id, toNode: nodes[1].id,
                connectionType: .excitatory, label: "Evidence", strength: 0.8
            ),
            // PFC-L5 ↔ AI (integration)
            NeuralConnection(
                fromNode: nodes[1].id, toNode: nodes[2].id,
                connectionType: .bidirectional, label: nil, strength: 0.6
            ),
            // AI → ACC
            NeuralConnection(
                fromNode: nodes[2].id, toNode: nodes[3].id,
                connectionType: .excitatory, label: "Intero PE", strength: 0.7
            ),
            // TRN → Pulvinar (inhibitory)
            NeuralConnection(
                fromNode: nodes[4].id, toNode: nodes[5].id,
                connectionType: .inhibitory, label: "GABA", strength: 0.9
            ),
            // Pulvinar → PFC-L5 L1
            NeuralConnection(
                fromNode: nodes[5].id, toNode: nodes[1].id,
                connectionType: .excitatory, label: "L1 drive", strength: 0.85
            ),
            // LC → TRN (suppression)
            NeuralConnection(
                fromNode: nodes[6].id, toNode: nodes[4].id,
                connectionType: .inhibitory, label: "Suppression", strength: 0.7
            ),
            // LC → AI (NE boost)
            NeuralConnection(
                fromNode: nodes[6].id, toNode: nodes[2].id,
                connectionType: .modulatory, label: "↑Πᵢ", strength: 0.8
            ),
            // BF → PPC (ACh)
            NeuralConnection(
                fromNode: nodes[7].id, toNode: nodes[0].id,
                connectionType: .modulatory, label: "↑Πₑ", strength: 0.7
            ),
            // PPC → Sₜ variable
            NeuralConnection(
                fromNode: nodes[0].id, toNode: nodes[8].id,
                connectionType: .excitatory, label: nil, strength: 0.9
            ),
            // LC → θₜ variable
            NeuralConnection(
                fromNode: nodes[6].id, toNode: nodes[9].id,
                connectionType: .modulatory, label: "↓θₜ", strength: 0.6
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and controls
            HStack {
                Text("APGI Neural Circuit")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Toggle("Labels", isOn: $showLabels)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Menu {
                    Button("Ignition Pathway") {
                        highlightedPathway = "ignition"
                    }
                    Button("Neuromodulation") {
                        highlightedPathway = "neuromod"
                    }
                    Button("All Pathways") {
                        highlightedPathway = nil
                    }
                } label: {
                    Label("Pathways", systemImage: "arrow.triangle.branch")
                }
                .menuStyle(.borderlessButton)
            }
            
            // Legend
            legendView
            
            // Main diagram
            GeometryReader { geometry in
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(diagramBackground)
                    
                    // Connections layer
                    ForEach(connections) { connection in
                        ConnectionLine(
                            connection: connection,
                            nodes: nodes,
                            size: geometry.size,
                            isHighlighted: shouldHighlight(connection),
                            animationPhase: animationPhase
                        )
                    }
                    
                    // Nodes layer
                    ForEach(nodes) { node in
                        NodeView(
                            node: node,
                            isSelected: selectedNode?.id == node.id,
                            isHovered: hoveredNode?.id == node.id,
                            showLabel: showLabels,
                            highContrast: highContrastMode
                        )
                        .position(
                            x: node.position.x * geometry.size.width,
                            y: node.position.y * geometry.size.height
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedNode = selectedNode?.id == node.id ? nil : node
                            }
                        }
                        .onHover { hovering in
                            hoveredNode = hovering ? node : nil
                        }
                    }
                }
            }
            .frame(height: 450)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            // Selected node details
            if let node = selectedNode {
                nodeDetailView(node)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
    
    // MARK: - Subviews
    
    private var legendView: some View {
        HStack(spacing: 20) {
            ForEach([
                ("Excitatory", Color.green),
                ("Inhibitory", Color.red),
                ("Modulatory", Color.purple),
                ("Bidirectional", Color.blue)
            ], id: \.0) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.1)
                        .frame(width: 8, height: 8)
                    Text(item.0)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                legendItem(shape: .circle, label: "Cortical")
                legendItem(shape: .roundedRect, label: "Subcortical")
                legendItem(shape: .diamond, label: "Neuromod")
                legendItem(shape: .hexagon, label: "Variable")
            }
        }
        .padding(.horizontal)
    }
    
    private enum LegendShape {
        case circle, roundedRect, diamond, hexagon
    }
    
    private func legendItem(shape: LegendShape, label: String) -> some View {
        HStack(spacing: 4) {
            Group {
                switch shape {
                case .circle:
                    Circle().fill(Color.blue.opacity(0.6))
                case .roundedRect:
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.6))
                case .diamond:
                    DiamondShape().fill(Color.yellow.opacity(0.6))
                case .hexagon:
                    HexagonShape().fill(Color.cyan.opacity(0.6))
                }
            }
            .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
    }
    
    private func nodeDetailView(_ node: NeuralNode) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Node indicator
            Circle()
                .fill(node.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(node.label)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("(\(node.abbreviation))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Text(node.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedNode = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(node.color.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var diagramBackground: some ShapeStyle {
        if highContrastMode {
            return AnyShapeStyle(colorScheme == .dark ? Color.black : Color.white)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(NSColor.controlBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func shouldHighlight(_ connection: NeuralConnection) -> Bool {
        guard let pathway = highlightedPathway else { return true }
        
        switch pathway {
        case "ignition":
            // Highlight PPC → PFC → Pulv pathway
            return [0, 4, 5].contains { idx in
                connections.indices.contains(idx) && connections[idx].id == connection.id
            }
        case "neuromod":
            // Highlight LC and BF connections
            return [6, 7, 8, 9].contains { idx in
                connections.indices.contains(idx) && connections[idx].id == connection.id
            }
        default:
            return true
        }
    }
}

// MARK: - Node View

struct NodeView: View {
    let node: NeuralNode
    let isSelected: Bool
    let isHovered: Bool
    let showLabel: Bool
    let highContrast: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Shape based on node type
                nodeShape
                    .foregroundStyle(nodeFill)
                    .frame(width: node.size, height: node.size)
                    .shadow(color: node.color.opacity(isSelected ? 0.5 : 0.2), radius: isSelected ? 10 : 4)
                
                // Abbreviation
                Text(node.abbreviation)
                    .font(.system(size: node.size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(isHovered ? 1.1 : (isSelected ? 1.15 : 1.0))
            .animation(.spring(response: 0.3), value: isHovered)
            .animation(.spring(response: 0.3), value: isSelected)
            
            // Label
            if showLabel {
                Text(node.label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: node.size * 1.5)
            }
        }
    }
    
    @ViewBuilder
    private var nodeShape: some View {
        switch node.nodeType {
        case .cortical:
            Circle()
        case .subcortical:
            RoundedRectangle(cornerRadius: 8)
        case .neuromodulator:
            DiamondShape()
        case .variable:
            HexagonShape()
        }
    }
    
    private var nodeFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [node.color, node.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(node.color.opacity(isHovered ? 0.9 : 0.8))
    }
}

// MARK: - Connection Line

struct ConnectionLine: View {
    let connection: NeuralConnection
    let nodes: [NeuralNode]
    let size: CGSize
    let isHighlighted: Bool
    let animationPhase: Double
    
    var body: some View {
        let fromNode = nodes.first { $0.id == connection.fromNode }
        let toNode = nodes.first { $0.id == connection.toNode }
        
        if let from = fromNode, let to = toNode {
            let startPoint = CGPoint(
                x: from.position.x * size.width,
                y: from.position.y * size.height
            )
            let endPoint = CGPoint(
                x: to.position.x * size.width,
                y: to.position.y * size.height
            )
            
            ZStack {
                // Main line
                Path { path in
                    path.move(to: startPoint)
                    
                    // Curved connection
                    let midPoint = CGPoint(
                        x: (startPoint.x + endPoint.x) / 2,
                        y: (startPoint.y + endPoint.y) / 2 - 20
                    )
                    path.addQuadCurve(to: endPoint, control: midPoint)
                }
                .stroke(
                    connection.connectionType.color.opacity(isHighlighted ? 0.8 : 0.2),
                    style: StrokeStyle(
                        lineWidth: CGFloat(connection.strength) * 3,
                        lineCap: .round,
                        dash: connection.connectionType.dashPattern
                    )
                )
                
                // Arrow head
                arrowHead(from: startPoint, to: endPoint)
                    .fill(connection.connectionType.color.opacity(isHighlighted ? 0.8 : 0.3))
                
                // Bidirectional arrow (if needed)
                if connection.connectionType == .bidirectional {
                    arrowHead(from: endPoint, to: startPoint)
                        .fill(connection.connectionType.color.opacity(isHighlighted ? 0.8 : 0.3))
                }
                
                // Label
                if let label = connection.label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(connection.connectionType.color)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(
                            x: (startPoint.x + endPoint.x) / 2,
                            y: (startPoint.y + endPoint.y) / 2 - 15
                        )
                }
            }
        }
    }
    
    private func arrowHead(from: CGPoint, to: CGPoint) -> Path {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6
        
        // Position arrow near the target node
        let distance = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
        let ratio = max(0, (distance - 35)) / distance
        let arrowPoint = CGPoint(
            x: from.x + (to.x - from.x) * ratio,
            y: from.y + (to.y - from.y) * ratio
        )
        
        return Path { path in
            path.move(to: arrowPoint)
            path.addLine(to: CGPoint(
                x: arrowPoint.x - arrowLength * cos(angle - arrowAngle),
                y: arrowPoint.y - arrowLength * sin(angle - arrowAngle)
            ))
            path.addLine(to: CGPoint(
                x: arrowPoint.x - arrowLength * cos(angle + arrowAngle),
                y: arrowPoint.y - arrowLength * sin(angle + arrowAngle)
            ))
            path.closeSubpath()
        }
    }
}

// MARK: - Custom Shapes

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        
        return Path { path in
            path.move(to: CGPoint(x: cx + w/2, y: cy))
            path.addLine(to: CGPoint(x: cx + w/4, y: cy - h/2))
            path.addLine(to: CGPoint(x: cx - w/4, y: cy - h/2))
            path.addLine(to: CGPoint(x: cx - w/2, y: cy))
            path.addLine(to: CGPoint(x: cx - w/4, y: cy + h/2))
            path.addLine(to: CGPoint(x: cx + w/4, y: cy + h/2))
            path.closeSubpath()
        }
    }
}

// MARK: - Ignition Process Diagram

struct IgnitionProcessDiagram: View {
    @State private var currentPhase = 0
    @State private var isAnimating = false
    
    private let phases: [(title: String, description: String, color: Color)] = [
        ("Stimulus", "External/internal event generates prediction error", .blue),
        ("Accumulation", "Sₜ builds via PPC L2/3 ramping activity", .purple),
        ("Threshold Check", "Compare Sₜ against dynamic θₜ", .orange),
        ("Ignition", "NMDA Ca²⁺ spike in L5 apical dendrites", .red),
        ("Broadcast", "Global workspace activation via long-range connections", .green),
        ("Refractory", "θₜ elevated, preventing immediate re-ignition", .gray)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ignition Process Flow")
                .font(.headline)
            
            // Phase visualization
            HStack(spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    VStack(spacing: 8) {
                        // Phase circle
                        ZStack {
                            Circle()
                                .fill(index <= currentPhase ? phase.color : phase.color.opacity(0.3))
                                .frame(width: 50, height: 50)
                            
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            if index == currentPhase && isAnimating {
                                Circle()
                                    .stroke(phase.color, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(1.2)
                                    .opacity(0.5)
                                    .animation(
                                        .easeInOut(duration: 1).repeatForever(autoreverses: true),
                                        value: isAnimating
                                    )
                            }
                        }
                        
                        // Title
                        Text(phase.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(index <= currentPhase ? .primary : .secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                    
                    // Connector arrow
                    if index < phases.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundStyle(index < currentPhase ? phases[index].color : .secondary.opacity(0.3))
                            .padding(.horizontal, 4)
                            .padding(.bottom, 30)
                    }
                }
            }
            
            // Current phase description
            if currentPhase < phases.count {
                let phase = phases[currentPhase]
                HStack(spacing: 12) {
                    Circle()
                        .fill(phase.color)
                        .frame(width: 12, height: 12)
                    
                    Text(phase.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(phase.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Controls
            HStack {
                Button {
                    currentPhase = 0
                    isAnimating = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                
                Button {
                    if currentPhase > 0 {
                        currentPhase -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(currentPhase == 0)
                
                Button {
                    isAnimating.toggle()
                    if isAnimating {
                        startAutoAdvance()
                    }
                } label: {
                    Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    if currentPhase < phases.count - 1 {
                        currentPhase += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .disabled(currentPhase == phases.count - 1)
                
                Spacer()
                
                Text("Phase \(currentPhase + 1) of \(phases.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func startAutoAdvance() {
        guard isAnimating else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard isAnimating else { return }
            
            withAnimation(.easeInOut) {
                if currentPhase < phases.count - 1 {
                    currentPhase += 1
                    startAutoAdvance()
                } else {
                    currentPhase = 0
                    startAutoAdvance()
                }
            }
        }
    }
}

// MARK: - Neural Circuit Visualizations View

struct NeuralCircuitVisualizationsView: View {
    @State private var selectedVisualization = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Interactive Visualizations")
                    .font(.title.bold())
                    .padding(.horizontal)
                
                // Visualization picker
                Picker("Visualization", selection: $selectedVisualization) {
                    Text("Neural Circuit").tag(0)
                    Text("Ignition Process").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Selected visualization
                Group {
                    switch selectedVisualization {
                    case 0:
                        APGINeuralCircuitDiagram()
                    case 1:
                        IgnitionProcessDiagram()
                    default:
                        APGINeuralCircuitDiagram()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preview

#Preview("Neural Circuit") {
    APGINeuralCircuitDiagram()
        .frame(width: 900, height: 700)
        .padding()
}

#Preview("Ignition Process") {
    IgnitionProcessDiagram()
        .frame(width: 700)
        .padding()
}
