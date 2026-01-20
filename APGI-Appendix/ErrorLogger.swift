import Foundation
import os.log
import Combine
import SwiftUI

// MARK: - Error Logger
@MainActor
class ErrorLogger: ObservableObject {
    static let shared = ErrorLogger()

    @Published var recentErrors: [LogEntry] = []
    @Published var isLoggingEnabled = true

    private let logFileURL: URL
    private let maxLogFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxLogEntries: Int = 1000
    private let osLog = OSLog(subsystem: "com.apgi.appendix", category: "Error")

    private init() {
        // Create log file in Application Support directory
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupportDir.appendingPathComponent("APGI-Appendix")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        logFileURL = appDir.appendingPathComponent("error.log")

        // Load recent errors on startup
        loadRecentErrors()
    }

    // MARK: - Public Methods

    func log(_ error: Error, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
        guard isLoggingEnabled else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: .error,
            message: error.localizedDescription,
            context: context,
            function: function,
            file: file,
            line: line
        )

        writeLogEntry(entry)

        // Also log to system logger
        os_log("%{public}@", log: osLog, type: .error, "\(context): \(error.localizedDescription)")
    }

    func log(_ message: String, level: LogLevel = .info, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
        guard isLoggingEnabled else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            context: context,
            function: function,
            file: file,
            line: line
        )

        writeLogEntry(entry)

        // Also log to system logger with appropriate level
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .critical:
            osLogType = .fault
        }

        os_log("%{public}@", log: osLog, type: osLogType, "\(context): \(message)")
    }

    func clearLogs() {
        recentErrors.removeAll()

        // Clear log file
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)

        log("Error logs cleared", level: .info, context: "ErrorLogger")
    }

    func exportLogs() -> URL? {
        return logFileURL
    }

    // MARK: - Private Methods

    private func writeLogEntry(_ entry: LogEntry) {
        // Add to recent errors
        recentErrors.append(entry)

        // Keep only recent errors in memory
        if recentErrors.count > maxLogEntries {
            recentErrors.removeFirst(recentErrors.count - maxLogEntries)
        }

        // Write to file
        let logLine = entry.formattedString + "\n"

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            // Check file size and rotate if necessary
            if let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
               let fileSize = attributes[.size] as? Int,
               fileSize > maxLogFileSize {
                rotateLogFile()
            }

            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logLine.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        } else {
            // Create new file
            try? logLine.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }

    private func rotateLogFile() {
        // Archive current log file
        let archiveURL = logFileURL.appendingPathExtension("old")

        // Remove existing archive if it exists
        try? FileManager.default.removeItem(at: archiveURL)

        // Move current log to archive
        try? FileManager.default.moveItem(at: logFileURL, to: archiveURL)
    }

    private func loadRecentErrors() {
        guard FileManager.default.fileExists(atPath: logFileURL.path) else { return }

        guard let data = try? String(contentsOf: logFileURL, encoding: .utf8) else { return }

        let lines = data.components(separatedBy: .newlines)
        let recentLines = Array(lines.suffix(100)) // Load last 100 lines

        for line in recentLines {
            if let entry = LogEntry(from: line) {
                recentErrors.append(entry)
            }
        }
    }
}

// MARK: - Log Entry Model
struct LogEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let context: String
    let function: String
    let file: String
    let line: Int

    private enum CodingKeys: String, CodingKey {
        case timestamp, level, message, context, function, file, line
    }

    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        let fileName = (file as NSString).lastPathComponent
        return "[\(formatter.string(from: timestamp))] [\(level.rawValue.uppercased())] [\(fileName):\(line)] \(function) - \(context.isEmpty ? message : "\(context): \(message)")"
    }

    init?(from string: String) {
        // Parse log line back to LogEntry
        // This is a simplified parser - in production you might want a more robust solution
        let pattern = #"^\[([^\]]+)\] \[([^\]]+)\] \[([^\]]+)\] ([^-]+) - (.*)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              match.numberOfRanges >= 6 else { return nil }

        // Extract timestamp
        let timestampRange = Range(match.range(at: 1), in: string)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        guard let timestamp = formatter.date(from: String(string[timestampRange])) else { return nil }

        // Extract level
        let levelRange = Range(match.range(at: 2), in: string)!
        guard let level = LogLevel(rawValue: String(string[levelRange]).lowercased()) else { return nil }

        // Extract file and line
        let fileLineRange = Range(match.range(at: 3), in: string)!
        let fileLineString = String(string[fileLineRange])
        let fileLineComponents = fileLineString.components(separatedBy: ":")
        let file = fileLineComponents.dropLast().joined(separator: ":")
        let line = Int(fileLineComponents.last ?? "0") ?? 0

        // Extract function
        let functionRange = Range(match.range(at: 4), in: string)!
        let function = String(string[functionRange]).trimmingCharacters(in: .whitespaces)

        // Extract message and context
        let messageContextRange = Range(match.range(at: 5), in: string)!
        let messageContextString = String(string[messageContextRange])

        var message = messageContextString
        var context = ""

        if let colonIndex = messageContextString.firstIndex(of: ":") {
            context = String(messageContextString[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            message = String(messageContextString[colonIndex...].dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        self.init(
            timestamp: timestamp,
            level: level,
            message: message,
            context: context,
            function: function,
            file: file,
            line: line
        )
    }

    init(timestamp: Date, level: LogLevel, message: String, context: String, function: String, file: String, line: Int) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.context = context
        self.function = function
        self.file = file
        self.line = line
    }
}

// MARK: - Log Level
enum LogLevel: String, CaseIterable, Codable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"

    var color: String {
        switch self {
        case .debug:
            return "gray"
        case .info:
            return "blue"
        case .warning:
            return "yellow"
        case .error:
            return "red"
        case .critical:
            return "purple"
        }
    }
}

// MARK: - Error Logger View
struct ErrorLoggerView: View {
    @StateObject private var errorLogger = ErrorLogger.shared
    @State private var selectedLevel: LogLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Error Logs")
                    .font(.title2.bold())

                Spacer()

                Toggle("Enable Logging", isOn: $errorLogger.isLoggingEnabled)

                Button("Clear Logs") {
                    errorLogger.clearLogs()
                }
                .foregroundColor(.red)

                if let exportURL = errorLogger.exportLogs() {
                    Button("Export") {
                        NSWorkspace.shared.selectFile(exportURL.path, inFileViewerRootedAtPath: "")
                    }
                }
            }

            // Filter
            HStack {
                Text("Filter:")

                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level as LogLevel?)
                    }
                }
                .pickerStyle(.menu)
            }

            // Log entries
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredErrors) { entry in
                        LogEntryView(entry: entry)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
        }
        .padding()
    }

    private var filteredErrors: [LogEntry] {
        if let selectedLevel = selectedLevel {
            return errorLogger.recentErrors.filter { $0.level == selectedLevel }
        } else {
            return errorLogger.recentErrors
        }
    }
}

// MARK: - Log Entry View
struct LogEntryView: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(entry.level.rawValue.uppercased())
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelColor.opacity(0.2))
                    .foregroundColor(levelColor)
                    .cornerRadius(4)
            }

            Text(entry.message)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)

            if !entry.context.isEmpty {
                Text("Context: \(entry.context)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("\(entry.function) @ \(URL(fileURLWithPath: entry.file).lastPathComponent):\(entry.line)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug:
            return .secondary
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - Global Logging Functions
func logError(_ error: Error, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
    Task { @MainActor in
        ErrorLogger.shared.log(error, context: context, function: function, file: file, line: line)
    }
}

func logInfo(_ message: String, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
    Task { @MainActor in
        ErrorLogger.shared.log(message, level: .info, context: context, function: function, file: file, line: line)
    }
}

func logWarning(_ message: String, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
    Task { @MainActor in
        ErrorLogger.shared.log(message, level: .warning, context: context, function: function, file: file, line: line)
    }
}

func logDebug(_ message: String, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
    Task { @MainActor in
        ErrorLogger.shared.log(message, level: .debug, context: context, function: function, file: file, line: line)
    }
}
