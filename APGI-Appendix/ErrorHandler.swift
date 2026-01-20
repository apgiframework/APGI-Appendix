import Foundation
import SwiftUI
import Combine

// MARK: - App Error Types

enum AppError: LocalizedError {
    case fileNotFound(String)
    case fileCorrupted(String)
    case parsingError(String)
    case searchError(String)
    case bookmarkError(String)
    case settingsError(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "File not found: \(filename)"
        case .fileCorrupted(let filename):
            return "File appears to be corrupted: \(filename)"
        case .parsingError(let details):
            return "Failed to parse content: \(details)"
        case .searchError(let details):
            return "Search failed: \(details)"
        case .bookmarkError(let details):
            return "Bookmark operation failed: \(details)"
        case .settingsError(let details):
            return "Settings error: \(details)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Please check if the file exists and try again."
        case .fileCorrupted:
            return "The file may be damaged. Try using a different file."
        case .parsingError:
            return "Check the file format and ensure it contains valid data."
        case .searchError:
            return "Try refining your search terms or check your connection."
        case .bookmarkError:
            return "Try removing and re-adding the bookmark."
        case .settingsError:
            return "Try resetting the settings to default values."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Error Handler

@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var lastError: AppError?
    @Published var showError = false

    private init() {}

    func handle(_ error: Error) {
        let appError: AppError

        if let appErr = error as? AppError {
            appError = appErr
        } else {
            appError = .unknown(error)
        }

        lastError = appError
        showError = true

        // Log error for debugging
        print("App Error: \(appError.errorDescription ?? "Unknown error")")
    }

    func clearError() {
        lastError = nil
        showError = false
    }
}

// MARK: - Error Handling View Modifier

struct ErrorHandlingModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.lastError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.errorDescription ?? "Unknown error")

                        if let suggestion = error.recoverySuggestion {
                            Text("Suggestion: \(suggestion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
    }
}

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

// MARK: - Safe Operations

extension Result {
    var appError: AppError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error as? AppError ?? .unknown(error)
        }
    }
}

extension Optional {
    func orThrow(_ error: AppError) throws -> Wrapped {
        guard let value = self else {
            throw error
        }
        return value
    }
}
