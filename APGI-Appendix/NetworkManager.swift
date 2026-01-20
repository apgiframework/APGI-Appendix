import Foundation
import Network
import SwiftUI
import Combine

// MARK: - Network Manager
@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isMonitoring = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        monitor = NWPathMonitor()
        setupMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.start(queue: queue)
        isMonitoring = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor.cancel()
        isMonitoring = false
    }
    
    private func setupMonitoring() {
        startMonitoring()
    }
    
    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else if path.usesInterfaceType(.other) {
            connectionType = .other
        } else {
            connectionType = nil
        }
    }
    
    // MARK: - Connection Status
    var statusText: String {
        if isConnected {
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
        if isConnected {
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
        isConnected ? .green : .red
    }
}

// MARK: - Network Status View
struct NetworkStatusView: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: networkManager.statusIcon)
                .foregroundColor(networkManager.statusColor)
                .font(.caption)
            
            if !networkManager.isConnected {
                Text("Offline")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .help(networkManager.statusText)
        .onAppear {
            if !networkManager.isMonitoring {
                networkManager.startMonitoring()
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
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Double = 24 // hours
    @AppStorage("useCellularData") private var useCellularData = false
    
    var body: some View {
        Form {
            Section(header: Text("Network Status")) {
                HStack {
                    Image(systemName: networkManager.statusIcon)
                        .foregroundColor(networkManager.statusColor)
                    
                    VStack(alignment: .leading) {
                        Text(networkManager.statusText)
                            .font(.headline)
                        Text("Connection is \(networkManager.isConnected ? "active" : "inactive")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Refresh") {
                        networkManager.startMonitoring()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section(header: Text("Remote Content")) {
                Toggle("Enable remote content fetching", isOn: $enableRemoteContent)
                
                if enableRemoteContent {
                    VStack(alignment: .leading) {
                        Text("Auto-refresh interval")
                        Picker("Interval", selection: $autoRefreshInterval) {
                            Text("Every hour").tag(1.0)
                            Text("Every 6 hours").tag(6.0)
                            Text("Every 12 hours").tag(12.0)
                            Text("Every 24 hours").tag(24.0)
                            Text("Every 3 days").tag(72.0)
                            Text("Every week").tag(168.0)
                        }
                        .pickerStyle(.menu)
                        
                        Toggle("Use cellular data", isOn: $useCellularData)
                            .help("Allow remote content downloads over cellular connection")
                    }
                }
            }
            
            Section(header: Text("Network Diagnostics")) {
                Button("Test Connection") {
                    testConnection()
                }
                .buttonStyle(.bordered)
                
                Button("Reset Network Settings") {
                    resetNetworkSettings()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func testConnection() {
        // Simple connection test
        let task = URLSession.shared.dataTask(with: URL(string: "https://api.apgi-framework.org")!) { _, response, error in
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
        enableRemoteContent = true
        autoRefreshInterval = 24
        useCellularData = false
        
        let alert = NSAlert()
        alert.messageText = "Network Settings Reset"
        alert.informativeText = "All network settings have been reset to their default values."
        alert.alertStyle = .informational
        alert.runModal()
    }
}
