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
