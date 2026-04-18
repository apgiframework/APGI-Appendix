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
        CGRect(
          x: -proxy.size.width * self.contentType.preloadThreshold,
          y: -proxy.size.height * self.contentType.preloadThreshold,
          width: proxy.size.width * (1 + 2 * self.contentType.preloadThreshold),
          height: proxy.size.height * (1 + 2 * self.contentType.preloadThreshold))
      )

      Group {
        if self.hasLoaded {
          self.content()
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else if isVisible && !self.hasLoaded {
          self.loadingView()
            .onAppear {
              self.loadContent()
            }
        } else {
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

  private var parsedTableView: some View {
    do {
      let parsedTable = try TableParser().parseMarkdownTable(self.markdownTable)
      return AnyView(parsedTable.toSwiftUIView())
    } catch {
      return AnyView(
        Text("Error loading table: \(error.localizedDescription)")
          .foregroundColor(.red)
      )
    }
  }

  var body: some View {
    LazyLoadingContainer(
      content: {
        VStack(alignment: .leading, spacing: 16) {
          self.parsedTableView
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
  @StateObject private var simulationEngine: APGIInferenceEngine
  @State private var engineError: String?

  init() {
    do {
      let engine = try APGIInferenceEngine(configuration: .default)
      self._simulationEngine = StateObject(wrappedValue: engine)
      self.engineError = nil
    } catch {
      // Create a fallback engine with minimal configuration
      do {
        let fallbackConfig = APGIConfiguration(
          inputSize: 32,
          hiddenSize: 64,
          numLevels: 2,
          dtMs: 10.0,
          maxWindowMs: 1000.0,
          theta0: 0.5,
          gamma: 0.1,
          delta: 0.2,
          lambdaUrg: 0.1,
          thetaMin: 0.1,
          thetaMax: 2.0,
          betaTransition: 5.0,
          hysteresis: 0.1,
          tauMin: 0.1,
          tauMax: 2.0,
          tauInteroBaseline: 1.0,
          tauExteroBaseline: 1.0,
          precisionMin: 0.1,
          precisionMax: 2.0,
          alphaBroadcast: 0.1,
          betaMaintenance: 0.01,
          energyDepletionRate: 0.1,
          energyMin: 0.1,
          energyMax: 1.0,
          allostaticIncreaseRate: 0.1,
          allostaticDecreaseRate: 0.2,
          allostaticMin: 0.0,
          allostaticMax: 1.0,
          maxRefractoryMs: 100.0,
          historyLength: 10,
          eps: 1e-6,
          reservoirScaling: 1.0,
          reservoirSparsity: 0.1,
          precisionHistoryMax: 10
        )
        let fallbackEngine = try APGIInferenceEngine(configuration: fallbackConfig)
        self._simulationEngine = StateObject(wrappedValue: fallbackEngine)
        self.engineError =
          "Using fallback configuration due to initialization error: \(error.localizedDescription)"
      } catch {
        // If even fallback fails, initialize with a bare-minimum config and report error
        let minimalConfig = APGIConfiguration(inputSize: 1, hiddenSize: 1, numLevels: 1)
        if let minimalEngine = try? APGIInferenceEngine(configuration: minimalConfig) {
          self._simulationEngine = StateObject(wrappedValue: minimalEngine)
        } else {
          let baseEngine = try! APGIInferenceEngine(configuration: minimalConfig)
          self._simulationEngine = StateObject(wrappedValue: baseEngine)
        }
        self.engineError =
          "Critical: Failed to initialize APGI engine: \(error.localizedDescription)"
      }
    }
  }

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
      let width = geometry.size.width
      let maxVisiblePoints = self.performanceManager.shouldLimitConcurrentOperations ? 50 : 200
      let pointsPerPixel = Double(data.count) / Double(width)
      let visiblePoints = min(maxVisiblePoints, Int(width * pointsPerPixel))

      let startIndex = max(0, data.count - visiblePoints)
      let endIndex = self.data.count

      Chart(Array(self.data[startIndex..<endIndex])) { point in
        LineMark(
          x: .value("Time", point.timestamp),
          y: .value("Value", point.value)
        )
        .foregroundStyle(.blue)
      }
      .onAppear {
        self.updateVisibleDataPoints(for: width)
      }
      .onChange(of: width) { _, newWidth in
        self.updateVisibleDataPoints(for: newWidth)
      }
    }
  }

  private func updateVisibleDataPoints(for width: CGFloat) {
    let maxVisiblePoints = self.performanceManager.shouldLimitConcurrentOperations ? 50 : 200
    let pointsPerPixel = Double(data.count) / Double(width)
    let visiblePoints = min(maxVisiblePoints, Int(width * pointsPerPixel))

    let startIndex = max(0, data.count - visiblePoints)
    let endIndex = self.data.count

    self.visibleDataPoints = Array(self.data[startIndex..<endIndex])
  }
}
