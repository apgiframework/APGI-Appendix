import SwiftUI
import Charts

struct LazyLoadingContainer<Content: View>: View {
    let content: () -> Content
    let contentType: ContentType
    @State private var isVisible = false
    @State private var hasLoaded = false
    @StateObject private var performanceManager = PerformanceManager.shared
    
    init(contentType: ContentType, @ViewBuilder content: @escaping () -> Content) {
        self.contentType = contentType
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible && hasLoaded {
                content()
                    .transition(performanceManager.shouldReduceAnimations ? 
                               .opacity : .asymmetric(
                                   insertion: .scale.combined(with: .opacity),
                                   removal: .opacity
                               ))
            } else if isVisible && !hasLoaded {
                loadingView
                    .onAppear {
                        loadContent()
                    }
            } else {
                placeholderView
            }
        }
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            if contentType == .heavy || contentType == .critical {
                // Unload heavy content when not visible to save memory
                hasLoaded = false
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Content not visible")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadContent() {
        Task {
            let loadingDelay = performanceManager.getOptimizedLoadingDelay(for: contentType)
            try await Task.sleep(nanoseconds: UInt64(loadingDelay * 1_000_000_000))
            
            await MainActor.run {
                hasLoaded = true
            }
        }
    }
}

// MARK: - Enhanced Lazy Loading for Specific Views

struct LazyChartView: View {
    let data: [ChartDataPoint]
    let title: String
    
    var body: some View {
        LazyLoadingContainer(contentType: .heavy) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 300)
            }
            .padding()
        }
    }
}

struct LazyTableView: View {
    let markdownTable: String
    
    var body: some View {
        LazyLoadingContainer(contentType: .medium) {
            VStack(alignment: .leading, spacing: 16) {
                if let parsedTable = try? TableParser().parseMarkdownTable(markdownTable) {
                    parsedTable.toSwiftUIView()
                } else {
                    Text("Failed to load table")
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
    }
}

struct LazySimulationView: View {
    @StateObject private var simulationEngine = APGIInferenceEngine(configuration: .default)
    
    var body: some View {
        LazyLoadingContainer(contentType: .critical) {
            APGISimulatorView()
                .environmentObject(simulationEngine)
        }
    }
}

// MARK: - Chart Data Model

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Performance-Optimized Chart

struct PerformanceOptimizedChart: View {
    let data: [ChartDataPoint]
    @State private var visibleDataPoints: [ChartDataPoint] = []
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            let _ = calculateVisibleRange(geometry.size.width)
            
            Chart(visibleDataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 300)
            .onChange(of: geometry.size.width) { _, newWidth in
                updateVisibleDataPoints(for: newWidth)
            }
            .onAppear {
                updateVisibleDataPoints(for: geometry.size.width)
            }
        }
    }
    
    private func calculateVisibleRange(_ width: CGFloat) -> Range<Int> {
        let maxVisiblePoints = performanceManager.shouldLimitConcurrentOperations ? 50 : 200
        let pointsPerPixel = Double(data.count) / Double(width)
        let visiblePoints = min(maxVisiblePoints, Int(width * pointsPerPixel))
        
        let startIndex = max(0, data.count - visiblePoints)
        let endIndex = data.count
        
        return startIndex..<endIndex
    }
    
    private func updateVisibleDataPoints(for width: CGFloat) {
        let range = calculateVisibleRange(width)
        visibleDataPoints = Array(data[range])
    }
}
