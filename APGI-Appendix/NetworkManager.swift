import Foundation
import SwiftUI
import Combine
import Network

@MainActor
final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = true
    @Published var lastError: NetworkError?
    
    private let session: URLSession
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        self.monitor = NWPathMonitor()
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public Methods
    
    func fetchExternalResource(url: URL) async throws -> Data {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            return data
        } catch let error as NetworkError {
            lastError = error
            throw error
        } catch {
            let networkError = NetworkError.unknown(error)
            lastError = networkError
            throw networkError
        }
    }
    
    func fetchExternalResourceWithFallback(
        primaryURL: URL,
        fallbackURL: URL? = nil
    ) async throws -> Data {
        do {
            return try await fetchExternalResource(url: primaryURL)
        } catch {
            if let fallbackURL = fallbackURL {
                do {
                    return try await fetchExternalResource(url: fallbackURL)
                } catch {
                    throw NetworkError.fallbackFailed(primaryError: error, fallbackError: error)
                }
            }
            throw error
        }
    }
    
    func validateURL(_ urlString: String) -> URL? {
        guard let url = URL(string: urlString) else { return nil }
        guard url.scheme == "http" || url.scheme == "https" else { return nil }
        return url
    }
    
    // MARK: - Retry Logic
    
    func fetchWithRetry<T>(
        url: URL,
        maxRetries: Int = 3,
        backoffMultiplier: Double = 2.0,
        initialDelay: TimeInterval = 1.0,
        operation: @escaping (URL) async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation(url)
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    let delay = initialDelay * pow(backoffMultiplier, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw NetworkError.retryExhausted(lastError ?? URLError(.unknown))
    }
}

// MARK: - Network Error Types

enum NetworkError: LocalizedError, Equatable {
    case noConnection
    case invalidResponse
    case serverError(Int)
    case timeout
    case invalidURL
    case unknown(Error)
    case fallbackFailed(primaryError: Error, fallbackError: Error)
    case retryExhausted(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .invalidResponse:
            return "Invalid server response received."
        case .serverError(let code):
            return "Server error occurred (HTTP \(code)). Please try again later."
        case .timeout:
            return "Request timed out. Please check your connection and try again."
        case .invalidURL:
            return "Invalid URL provided."
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        case .fallbackFailed(let primaryError, let fallbackError):
            return "Primary and fallback resources failed. Primary: \(primaryError.localizedDescription), Fallback: \(fallbackError.localizedDescription)"
        case .retryExhausted(let error):
            return "Request failed after multiple retries: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again."
        case .serverError:
            return "Wait a few moments and try again, or contact support if the issue persists."
        case .timeout:
            return "Check your connection speed and try again."
        case .invalidURL:
            return "Verify the URL is correct and try again."
        default:
            return "Try again later or contact support if the issue persists."
        }
    }
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noConnection, .noConnection),
             (.invalidResponse, .invalidResponse),
             (.timeout, .timeout),
             (.invalidURL, .invalidURL):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}

// MARK: - Network Status View

struct NetworkStatusView: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        if !networkManager.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.orange)
                Text("Offline - Some features may be unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Retry View Modifier

struct RetryableOperation: ViewModifier {
    let operation: () async throws -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var networkManager = NetworkManager.shared
    
    func body(content: Content) -> some View {
        VStack(spacing: 12) {
            content
            
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Button("Retry") {
                            Task {
                                await performOperation()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if networkManager.lastError != nil {
                            Button("Details") {
                                // Show error details in an alert or sheet
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .onAppear {
            Task {
                await performOperation()
            }
        }
    }
    
    private func performOperation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

extension View {
    func retryable(operation: @escaping () async throws -> Void) -> some View {
        modifier(RetryableOperation(operation: operation))
    }
}

// Import Network framework for monitoring
import Network
