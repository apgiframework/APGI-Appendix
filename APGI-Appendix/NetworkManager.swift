import Combine
import Foundation
import Network
import SwiftUI

// MARK: - Network Manager

@MainActor
class NetworkManager: ObservableObject {
  static let shared = NetworkManager()

  @Published var isConnected = true
  @Published var connectionType: NWInterface.InterfaceType?
  @Published var isMonitoring = false

  private var monitor: NWPathMonitor?
  private let queue = DispatchQueue(label: "NetworkMonitor")
  private var cancellables = Set<AnyCancellable>()

  private init() {
    self.setupMonitoring()
  }

  deinit {
    monitor?.cancel()
  }

  // MARK: - Network Monitoring

  /// Start monitoring network connectivity
  /// Creates a new monitor instance if needed (NWPathMonitor cannot be reused after cancel)
  func startMonitoring() {
    guard !self.isMonitoring else { return }

    // Create new monitor instance if none exists or previous was canceled
    if self.monitor == nil {
      self.monitor = NWPathMonitor()
    }

    self.monitor?.pathUpdateHandler = { [weak self] path in
      Task { @MainActor [weak self] in
        guard let self else { return }
        self.updateConnectionStatus(path)
      }
    }

    self.monitor?.start(queue: self.queue)
    self.isMonitoring = true
  }

  /// Stop monitoring network connectivity
  /// Note: Once canceled, the monitor cannot be restarted - a new instance will be created on next start
  func stopMonitoring() {
    guard self.isMonitoring else { return }

    self.monitor?.cancel()
    self.monitor = nil  // Clear reference so new instance is created on restart
    self.isMonitoring = false
  }

  /// Restart monitoring with a fresh monitor instance
  /// Use this when you need to ensure monitoring is working after network changes
  func restartMonitoring() {
    self.stopMonitoring()
    // Small delay to ensure previous monitor is fully released
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.startMonitoring()
    }
  }

  private func setupMonitoring() {
    self.startMonitoring()
  }

  private func updateConnectionStatus(_ path: NWPath) {
    self.isConnected = path.status == .satisfied

    // Determine connection type
    if path.usesInterfaceType(.wifi) {
      self.connectionType = .wifi
    } else if path.usesInterfaceType(.cellular) {
      self.connectionType = .cellular
    } else if path.usesInterfaceType(.wiredEthernet) {
      self.connectionType = .wiredEthernet
    } else if path.usesInterfaceType(.other) {
      self.connectionType = .other
    } else {
      self.connectionType = nil
    }
  }

  // MARK: - Connection Status

  var statusText: String {
    if self.isConnected {
      if let type = connectionType {
        switch type {
        case .wifi:
          return "Connected (Wi-Fi)"
        case .cellular:
          return "Connected (Cellular)"
        case .wiredEthernet:
          return "Connected (Ethernet)"
        case .other:
          return "Connected"
        default:
          return "Connected"
        }
      } else {
        return "Connected"
      }
    } else {
      return "Offline"
    }
  }

  var statusIcon: String {
    if self.isConnected {
      if let type = connectionType {
        switch type {
        case .wifi:
          return "wifi"
        case .cellular:
          return "antenna.radiowaves.left.and.right"
        case .wiredEthernet:
          return "cable.connector"
        default:
          return "network"
        }
      } else {
        return "network"
      }
    } else {
      return "wifi.slash"
    }
  }

  var statusColor: Color {
    self.isConnected ? .green : .red
  }
}

// MARK: - Network Status View

struct NetworkStatusView: View {
  @StateObject private var networkManager = NetworkManager.shared

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: self.networkManager.statusIcon)
        .foregroundColor(self.networkManager.statusColor)
        .font(.caption)

      if !self.networkManager.isConnected {
        Text("Offline")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .help(self.networkManager.statusText)
    .onAppear {
      if !self.networkManager.isMonitoring {
        self.networkManager.startMonitoring()
      }
    }
    .onDisappear {
      // Don't stop monitoring to keep status updated
    }
  }
}

// MARK: - Network Settings View

struct NetworkSettingsView: View {
  @StateObject private var networkManager = NetworkManager.shared
  @AppStorage("enableRemoteContent") private var enableRemoteContent = true
  @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Double = 24  // hours
  @AppStorage("useCellularData") private var useCellularData = false

  var body: some View {
    Form {
      Section(header: Text("Network Status")) {
        HStack {
          Image(systemName: self.networkManager.statusIcon)
            .foregroundColor(self.networkManager.statusColor)

          VStack(alignment: .leading) {
            Text(self.networkManager.statusText)
              .font(.headline)
            Text("Connection is \(self.networkManager.isConnected ? "active" : "inactive")")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()

          Button("Refresh") {
            self.networkManager.startMonitoring()
          }
          .buttonStyle(.bordered)
        }
      }

      Section(header: Text("Remote Content")) {
        Toggle("Enable remote content fetching", isOn: self.$enableRemoteContent)

        if self.enableRemoteContent {
          VStack(alignment: .leading) {
            Text("Auto-refresh interval")
            Picker("Interval", selection: self.$autoRefreshInterval) {
              Text("Every hour").tag(1.0)
              Text("Every 6 hours").tag(6.0)
              Text("Every 12 hours").tag(12.0)
              Text("Every 24 hours").tag(24.0)
              Text("Every 3 days").tag(72.0)
              Text("Every week").tag(168.0)
            }
            .pickerStyle(.menu)

            Toggle("Use cellular data", isOn: self.$useCellularData)
              .help("Allow remote content downloads over cellular connection")
          }
        }
      }

      Section(header: Text("Network Diagnostics")) {
        Button("Test Connection") {
          self.testConnection()
        }
        .buttonStyle(.bordered)

        Button("Reset Network Settings") {
          self.resetNetworkSettings()
        }
        .buttonStyle(.bordered)
        .foregroundColor(.red)
      }
    }
    .padding()
    .frame(width: 400, height: 300)
  }

  func testConnection() {
    // Simple connection test
    guard let url = URL(string: "https://api.apgi-framework.org") else {
      DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "Connection Test Failed"
        alert.informativeText = "Invalid URL for connection test."
        alert.alertStyle = .warning
        alert.runModal()
      }
      return
    }

    let task = URLSession.shared.dataTask(with: url) { _, _, error in
      DispatchQueue.main.async {
        if let error = error {
          let alert = NSAlert()
          alert.messageText = "Connection Test Failed"
          alert.informativeText = error.localizedDescription
          alert.alertStyle = .warning
          alert.runModal()
        } else {
          let alert = NSAlert()
          alert.messageText = "Connection Test Successful"
          alert.informativeText = "Network connection is working properly."
          alert.alertStyle = .informational
          alert.runModal()
        }
      }
    }
    task.resume()
  }

  private func resetNetworkSettings() {
    self.enableRemoteContent = true
    self.autoRefreshInterval = 24
    self.useCellularData = false

    let alert = NSAlert()
    alert.messageText = "Network Settings Reset"
    alert.informativeText = "All network settings have been reset to their default values."
    alert.alertStyle = .informational
    alert.runModal()
  }
}
