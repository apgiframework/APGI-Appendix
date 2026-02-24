import Charts
import SwiftUI

/// Enhanced lazy loading container with improved responsiveness
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
                CGRect(x: -proxy.size.width * self.contentType.preloadThreshold,
                       y: -proxy.size.height * self.contentType.preloadThreshold,
                       width: proxy.size.width * (1 + 2 * self.contentType.preloadThreshold),
                       height: proxy.size.height * (1 + 2 * self.contentType.preloadThreshold))
            )

            Group {
                if self.hasLoaded {
                    self.content()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                else if isVisible && !self.hasLoaded {
                    self.loadingView()
                        .onAppear {
                            self.loadContentWithDelay()
                        }
                }
                else {
                    self.placeholder()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: self.hasLoaded)
        }
        .onAppear {
            self.isVisible = true
        }
        .onDisappear {
            if self.contentType == .heavy || self.contentType == .critical {
                // Unload heavy content when not visible to save memory
                self.hasLoaded = false
                self.isLoading = false
            }
        }
    }

    private func loadContentWithDelay() {
        guard !self.isLoading else { return }

        self.isLoading = true

        // Add delay for heavy content to improve perceived performance
        DispatchQueue.main.asyncAfter(deadline: .now() + self.contentType.loadDelay) {
            self.loadContent()
        }
    }

    private func loadContent() {
        Task {
            await MainActor.run {
                self.hasLoaded = true
                self.isLoading = false
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
                    Text(self.title)
                        .font(.headline)

                    Chart(self.data) { point in
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
                    }
                    else {
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
                    .environmentObject(self.simulationEngine)
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
            Chart(self.visibleDataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 300)
            .onChange(of: geometry.size.width) { _, newWidth in
                self.updateVisibleDataPoints(for: newWidth)
            }
            .onAppear {
                let _ = self.calculateVisibleRange(geometry.size.width)
                self.updateVisibleDataPoints(for: geometry.size.width)
            }
        }
    }

    private func calculateVisibleRange(_ width: CGFloat) -> Range<Int> {
        let maxVisiblePoints = self.performanceManager.shouldLimitConcurrentOperations ? 50 : 200
        let pointsPerPixel = Double(data.count) / Double(width)
        let visiblePoints = min(maxVisiblePoints, Int(width * pointsPerPixel))

        let startIndex = max(0, data.count - visiblePoints)
        let endIndex = self.data.count

        return startIndex ..< endIndex
    }

    private func updateVisibleDataPoints(for width: CGFloat) {
        let range = self.calculateVisibleRange(width)
        self.visibleDataPoints = Array(self.data[range])
    }
}
