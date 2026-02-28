import Combine
import Foundation
import os.log
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
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to find application support directory")
        }
        let appDir = appSupportDir.appendingPathComponent("APGI-Appendix")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        self.logFileURL = appDir.appendingPathComponent("error.log")

        // Load recent errors on startup
        self.loadRecentErrors()
    }

    // MARK: - Public Methods

    func log(_ error: Error, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
        guard self.isLoggingEnabled else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: .error,
            message: error.localizedDescription,
            context: context,
            function: function,
            file: file,
            line: line
        )

        self.writeLogEntry(entry)

        // Also log to system logger
        os_log("%{public}@", log: self.osLog, type: .error, "\(context): \(error.localizedDescription)")
    }

    func log(_ message: String, level: LogLevel = .info, context: String = "", function: String = #function, file: String = #fileID, line: Int = #line) {
        guard self.isLoggingEnabled else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            context: context,
            function: function,
            file: file,
            line: line
        )

        self.writeLogEntry(entry)

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

        os_log("%{public}@", log: self.osLog, type: osLogType, "\(context): \(message)")
    }

    func clearLogs() {
        self.recentErrors.removeAll()

        // Clear log file
        try? "".write(to: self.logFileURL, atomically: true, encoding: .utf8)

        self.log("Error logs cleared", level: .info, context: "ErrorLogger")
    }

    func exportLogs() -> URL? {
        return self.logFileURL
    }

    // MARK: - Private Methods

    private func writeLogEntry(_ entry: LogEntry) {
        // Add to recent errors
        self.recentErrors.append(entry)

        // Keep only recent errors in memory
        if self.recentErrors.count > self.maxLogEntries {
            self.recentErrors.removeFirst(self.recentErrors.count - self.maxLogEntries)
        }

        // Write to file
        let logLine = entry.formattedString + "\n"

        if FileManager.default.fileExists(atPath: self.logFileURL.path) {
            // Check file size and rotate if necessary
            if let attributes = try? FileManager.default.attributesOfItem(atPath: logFileURL.path),
               let fileSize = attributes[.size] as? Int,
               fileSize > maxLogFileSize
            {
                self.rotateLogFile()
            }

            // Append to existing file
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logLine.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        }
        else {
            // Create new file
            try? logLine.write(to: self.logFileURL, atomically: true, encoding: .utf8)
        }
    }

    private func rotateLogFile() {
        // Archive current log file
        let archiveURL = self.logFileURL.appendingPathExtension("old")

        // Remove existing archive if it exists
        try? FileManager.default.removeItem(at: archiveURL)

        // Move current log to archive
        try? FileManager.default.moveItem(at: self.logFileURL, to: archiveURL)
    }

    private func loadRecentErrors() {
        guard FileManager.default.fileExists(atPath: self.logFileURL.path) else { return }

        guard let data = try? String(contentsOf: logFileURL, encoding: .utf8) else { return }

        let lines = data.components(separatedBy: .newlines)
        let recentLines = Array(lines.suffix(100)) // Load last 100 lines

        for line in recentLines {
            if let entry = LogEntry(from: line) {
                self.recentErrors.append(entry)
            }
        }
    }
}

// MARK: - Log Entry Model

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String
    let context: String
    let function: String
    let file: String
    let line: Int

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, level, message, context, function, file, line
    }

    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        let fileName = (file as NSString).lastPathComponent
        return "[\(formatter.string(from: self.timestamp))] [\(self.level.rawValue.uppercased())] [\(fileName):\(self.line)] \(self.function) - \(self.context.isEmpty ? self.message : "\(self.context): \(self.message)")"
    }

    init?(from string: String) {
        // Parse log line back to LogEntry - improved robust parser
        // Format: [timestamp] [level] [file:line] function - context: message
        // Or:     [timestamp] [level] [file:line] function - message

        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = nil

        // Skip opening bracket and parse timestamp
        guard scanner.scanString("[") != nil,
              let timestampStr = scanner.scanUpToString("]"),
              scanner.scanString("]") != nil else { return nil }

        // Parse level
        guard scanner.scanString(" [") != nil,
              let levelStr = scanner.scanUpToString("]"),
              scanner.scanString("]") != nil else { return nil }

        // Parse file:line
        guard scanner.scanString(" [") != nil,
              let fileLineStr = scanner.scanUpToString("]"),
              scanner.scanString("]") != nil else { return nil }

        // Skip space and parse function (everything until " - ")
        guard scanner.scanString(" ") != nil,
              let function = scanner.scanUpToString(" - ") else { return nil }

        // Skip " - " and parse the rest
        guard scanner.scanString(" - ") != nil else { return nil }

        // Parse the remaining part (message with optional context)
        let remaining = String(string[scanner.currentIndex...])

        // Parse timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        guard let timestamp = formatter.date(from: timestampStr) else { return nil }

        // Parse level
        guard let level = LogLevel(rawValue: levelStr.lowercased()) else { return nil }

        // Parse file and line
        let fileLineComponents = fileLineStr.components(separatedBy: ":")
        guard fileLineComponents.count >= 2,
              let line = Int(fileLineComponents.last ?? "0") else { return nil }
        let file = fileLineComponents.dropLast().joined(separator: ":")

        // Parse message and context - improved logic
        var message = remaining
        var context = ""

        // Look for context: message pattern, but be careful with colons in messages
        // Context typically comes before the first colon followed by a space
        if let firstColonIndex = remaining.firstIndex(of: ":"),
           firstColonIndex != remaining.startIndex,
           remaining[remaining.index(after: firstColonIndex)] == " " ||
           remaining[remaining.index(after: firstColonIndex)] == "\n" ||
           firstColonIndex == remaining.index(before: remaining.endIndex)
        {
            // Check if this looks like a context separator (word: message)
            let potentialContext = remaining[..<firstColonIndex]
            if potentialContext.rangeOfCharacter(from: .whitespaces) == nil ||
                potentialContext.trimmingCharacters(in: .whitespaces).count < 20
            {
                // Likely a context: message pattern
                context = String(potentialContext).trimmingCharacters(in: .whitespaces)
                message = String(remaining[remaining.index(after: firstColonIndex)...]).trimmingCharacters(in: .whitespaces)
            }
        }

        self.init(
            timestamp: timestamp,
            level: level,
            message: message,
            context: context,
            function: function.trimmingCharacters(in: .whitespaces),
            file: file,
            line: line
        )
    }

    init(id: UUID = UUID(), timestamp: Date, level: LogLevel, message: String, context: String, function: String, file: String, line: Int) {
        self.id = id
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
    case debug
    case info
    case warning
    case error
    case critical

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

                Toggle("Enable Logging", isOn: self.$errorLogger.isLoggingEnabled)

                Button("Clear Logs") {
                    self.errorLogger.clearLogs()
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

                Picker("Level", selection: self.$selectedLevel) {
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
                    ForEach(self.filteredErrors) { entry in
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
            return self.errorLogger.recentErrors.filter { $0.level == selectedLevel }
        }
        else {
            return self.errorLogger.recentErrors
        }
    }
}

// MARK: - Log Entry View

struct LogEntryView: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(self.entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(self.entry.level.rawValue.uppercased())
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(self.levelColor.opacity(0.2))
                    .foregroundColor(self.levelColor)
                    .cornerRadius(4)
            }

            Text(self.entry.message)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)

            if !self.entry.context.isEmpty {
                Text("Context: \(self.entry.context)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("\(self.entry.function) @ \(URL(fileURLWithPath: self.entry.file).lastPathComponent):\(self.entry.line)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }

    private var levelColor: Color {
        switch self.entry.level {
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
