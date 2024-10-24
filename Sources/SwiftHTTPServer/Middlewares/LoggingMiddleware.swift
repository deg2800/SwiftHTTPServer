//
//  LoggingMiddleware.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/23/24.
//
import Foundation

class LoggingMiddleware: Middleware {
    private let logFileURL: URL
    private let maxFileSize: UInt64 = 1024 * 1024 * 5  // 5MB log rotation size
    
    init(logFilePath: String) {
        self.logFileURL = URL(fileURLWithPath: logFilePath)
        if !FileManager.default.fileExists(atPath: logFilePath) {
            FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }
    }
    
    func handle(context: ContextWrapper, next: @escaping (ContextWrapper) -> Void) {
        printColored("Handling \(YELLOW)Logging\(BLUE) Middleware", color: BLUE)
        if context.parameters["uri"] ?? "" != "/admin/log" {
            var ipAddress: String = ""
            let nginxProxyRealIP = context.parameters["nginx-proxy-real-ip"] ?? ""
            if !nginxProxyRealIP.isEmpty {
                ipAddress = nginxProxyRealIP
            } else {
                ipAddress = "\(context.context.remoteAddress?.ipAddress ?? "Unknown IP")"
            }
            var newRequest = "** New Request: \(Date())\n"
            let incomingIP = "Incoming request from \(ipAddress)\n"
            let userAgent = "User Agent: [\(context.parameters["user-agent"] ?? "Unknown User Agent")]\n"
            let referrer = "Referrer: \(context.parameters["referrer"] ?? "Unknown Referrer")\n"
            let methodAndURI = "Received \(context.parameters["method"] ?? "Unknown Method") request: \(context.parameters["uri"] ?? "Unknown URI")\n"
            
            newRequest += "\(incomingIP)\(userAgent)\(referrer)\(methodAndURI)\n"
            rotateLogFileIfNeeded()
            
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                if let data = newRequest.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            printColored("Skipping logging for admin/log endpoint", color: YELLOW)
        }
        
        next(context)
    }
    
    private func rotateLogFileIfNeeded() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
            if let fileSize = attributes[.size] as? UInt64, fileSize > maxFileSize {
                let newPath = logFileURL.deletingLastPathComponent().appendingPathComponent("log-\(Date().timeIntervalSince1970).txt")
                try FileManager.default.moveItem(at: logFileURL, to: newPath)
                FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
            }
        } catch {
            print("Error during log rotation: \(error)")
        }
    }
    
    func getLogEntries() -> [LogEntry] {
            do {
                let logData = try String(contentsOf: logFileURL, encoding: .utf8)
                let parser = LogParser()
                return parser.parseLogFile(logData)
            } catch {
                print("Error reading log file: \(error)")
                return []
            }
        }
}

struct LogEntry {
    let timestamp: Date
    let ipAddress: String
    let userAgent: String
    let referrer: String
    let method: String
    let uri: String
}

class LogParser {
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    }
    
    func parseLogFile(_ logContent: String) -> [LogEntry] {
        var logEntries = [LogEntry]()
        var logSections = logContent.components(separatedBy: "** New Request: ")
        logSections.removeFirst()

        for section in logSections {
            guard !section.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            if let logEntry = parseLogSection(section) {
                logEntries.append(logEntry)
            }
        }
        
        return logEntries
    }
    
    private func parseLogSection(_ section: String) -> LogEntry? {
        let lines = section.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count >= 4 else { return nil }
        guard let timestamp = dateFormatter.date(from: lines[0].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        let ipAddress = extractValue(from: lines[1], prefix: "Incoming request from")
        let userAgent = extractValue(from: lines[2], prefix: "User Agent: [\"", suffix: "\"]")
        let referrer = extractValue(from: lines[3], prefix: "Referrer: [\"", suffix: "\"]")
        let methodLine = lines[4]
        
        guard let methodRange = methodLine.range(of: "Received ")?.upperBound,
              let uriRange = methodLine.range(of: " request: ")?.upperBound else {
            return nil
        }
        
        let method = String(methodLine[methodRange..<uriRange].dropLast(9))
        let uri = String(methodLine[uriRange...])

        return LogEntry(timestamp: timestamp, ipAddress: ipAddress, userAgent: userAgent, referrer: referrer, method: method, uri: uri)
    }
    
    private func extractValue(from line: String, prefix: String, suffix: String = "") -> String {
        guard let rangeStart = line.range(of: prefix)?.upperBound else { return "" }
        let valueStart = line[rangeStart...].trimmingCharacters(in: .whitespaces)
        
        if suffix.isEmpty {
            return valueStart
        } else if let rangeEnd = valueStart.range(of: suffix)?.lowerBound {
            return String(valueStart[..<rangeEnd]).trimmingCharacters(in: .whitespaces)
        }
        
        return valueStart
    }
}
