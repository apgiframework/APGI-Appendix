import SwiftUI
import Charts

// Enhanced lazy loading container with improved responsiveness
struct LazyLoadingContainer<Content: View, Placeholder: View, Loading: View>: View {
    let content: () -> Content
    let placeholder: () -> Placeholder
    let loadingView: () -> Loading
    let contentType: ContentType

    @State private var isVisible = false
    @State private var hasLoaded = false
    @State private var isLoading = false

    enum ContentType {
        case light, medium, heavy, critical

        var loadDelay: TimeInterval {
            switch self {
            case .light: return 0.0
            case .medium: return 0.1
            case .heavy: return 0.2
            case .critical: return 0.3
            }
        }

        var preloadThreshold: Double {
            switch self {
            case .light: return 0.0
            case .medium: return 0.1
            case .heavy: return 0.2
            case .critical: return 0.3
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let isVisible = proxy.frame(in: .global).intersects(
                CGRect(x: -proxy.size.width * contentType.preloadThreshold,
                      y: -proxy.size.height * contentType.preloadThreshold,
                      width: proxy.size.width * (1 + 2 * contentType.preloadThreshold),
                      height: proxy.size.height * (1 + 2 * contentType.preloadThreshold))
            )

            Group {
                if hasLoaded {
                    content()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if isVisible && !hasLoaded {
                    loadingView()
                        .onAppear {
                            loadContentWithDelay()
                        }
                } else {
                    placeholder()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: hasLoaded)
        }
        .onAppear {
            self.isVisible = true
        }
        .onDisappear {
            if contentType == .heavy || contentType == .critical {
                // Unload heavy content when not visible to save memory
                hasLoaded = false
                isLoading = false
            }
        }
    }

    private func loadContentWithDelay() {
        guard !isLoading else { return }

        isLoading = true

        // Add delay for heavy content to improve perceived performance
        DispatchQueue.main.asyncAfter(deadline: .now() + contentType.loadDelay) {
            loadContent()
        }
    }

    private func loadContent() {
        Task {
            await MainActor.run {
                hasLoaded = true
                isLoading = false
            }
        }
    }
}

// MARK: - Enhanced Lazy Loading for Specific Views

struct LazyChartView: View {
    let data: [ChartDataPoint]
    let title: String

    var body: some View {
        LazyLoadingContainer(
            content: {
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
            },
            placeholder: {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Chart will load when visible")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            loadingView: {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading chart...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            contentType: .heavy
        )
    }
}

struct LazyTableView: View {
    let markdownTable: String

    var body: some View {
        LazyLoadingContainer(
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    if let parsedTable = try? TableParser().parseMarkdownTable(markdownTable) {
                        parsedTable.toSwiftUIView()
                    } else {
                        Text("Failed to load table")
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            },
            placeholder: {
                VStack(spacing: 12) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Table will load when visible")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            loadingView: {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading table...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            contentType: .medium
        )
    }
}

struct LazySimulationView: View {
    @StateObject private var simulationEngine = APGIInferenceEngine(configuration: .default)

    var body: some View {
        LazyLoadingContainer(
            content: {
                APGISimulatorView()
                    .environmentObject(simulationEngine)
            },
            placeholder: {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Simulation will load when visible")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            loadingView: {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading simulation...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            },
            contentType: .critical
        )
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
            Chart(visibleDataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 300)
            .onChange(of: geometry.size.width) { oldWidth, newWidth in
                updateVisibleDataPoints(for: newWidth)
            }
            .onAppear {
                let _ = calculateVisibleRange(geometry.size.width)
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
