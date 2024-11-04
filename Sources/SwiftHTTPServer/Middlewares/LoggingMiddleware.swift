//
//  LoggingMiddleware.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/23/24.
//

import Foundation
import SQLite

class LoggingMiddleware: Middleware {
    let database: Connection
    private let logTable = Table("logs")
    private let id = SQLite.Expression<Int64>("id")
    private let timestamp = SQLite.Expression<Date>("timestamp")
    private let ipAddress = SQLite.Expression<String>("ip_address")
    private let userAgent = SQLite.Expression<String>("user_agent")
    private let referrer = SQLite.Expression<String>("referrer")
    private let method = SQLite.Expression<String>("method")
    private let uri = SQLite.Expression<String>("uri")
    private let headers = SQLite.Expression<String>("headers")

    init(database: Connection) {
        printColored("Datebase initialization", color: MAGENTA)
        self.database = database
        createLogTableIfNeeded()
    }

    private func createLogTableIfNeeded() {
        printColored("Creating logs table if needed", color: MAGENTA)
        do {
            try database.run(logTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(timestamp)
                t.column(ipAddress)
                t.column(userAgent)
                t.column(referrer)
                t.column(method)
                t.column(uri)
                t.column(headers)
            })
        } catch {
            print("Error creating logs table: \(error)")
        }
    }

    func handle(context: ContextWrapper, next: @escaping (ContextWrapper) -> Void) {
        let uri = context.parameters["uri"] ?? ""
        
        if uri.hasPrefix("/admin/log") || uri.hasPrefix("/css/") {
            next(context)
            return
        }
        
        let ipAddress = context.parameters["nginx-proxy-real-ip"] ?? context.context.remoteAddress?.ipAddress ?? "Unknown IP"
        let userAgent = context.parameters["user-agent"] ?? "Unknown User Agent"
        let referrer = context.parameters["referrer"] ?? "Unknown Referrer"
        let method = context.parameters["method"] ?? "Unknown Method"
        
        let headersData = try? JSONSerialization.data(withJSONObject: context.parameters, options: .prettyPrinted)
        let headersString = headersData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        printColored("IP Address: \(ipAddress) | User Agent: \(userAgent) | Referrer: \(referrer) | Method: \(method) | URI: \(uri) | Headers: \(headersString)", color: MAGENTA)
        
        let logEntry = LogEntry(
            id: 0,
            timestamp: Date(),
            ipAddress: ipAddress,
            userAgent: userAgent,
            referrer: referrer,
            method: method,
            uri: uri,
            headers: headersString
        )

        printColored("Log entry saved: \(logEntry)", color: YELLOW)
        if shouldLogEntry(logEntry) {
            DispatchQueue.global(qos: .background).async {
                self.saveLogEntry(logEntry)
            }
        }

        next(context)
    }

    private func saveLogEntry(_ logEntry: LogEntry) {
        do {
            try database.run(logTable.insert(
                timestamp <- logEntry.timestamp,
                ipAddress <- logEntry.ipAddress,
                userAgent <- logEntry.userAgent,
                referrer <- logEntry.referrer,
                method <- logEntry.method,
                uri <- logEntry.uri,
                headers <- logEntry.headers
            ))
        } catch {
            print("Error saving log entry: \(error)")
        }
    }

    func getLogEntries() -> [LogEntry] {
        var logs = [LogEntry]()
        
        do {
            for log in try database.prepare(logTable) {
                logs.append(LogEntry(
                    id: log[id],
                    timestamp: log[timestamp],
                    ipAddress: log[ipAddress],
                    userAgent: log[userAgent],
                    referrer: log[referrer],
                    method: log[method],
                    uri: log[uri],
                    headers: log[headers]
                ))
            }
        } catch {
            print("Error fetching log entries: \(error)")
        }
        
        return logs
    }
    
    func getLogEntry(by id: Int64) -> LogEntry? {
        do {
            if let log = try database.pluck(logTable.filter(self.id == id)) {
                return LogEntry(
                    id: log[self.id],
                    timestamp: log[timestamp],
                    ipAddress: log[ipAddress],
                    userAgent: log[userAgent],
                    referrer: log[referrer],
                    method: log[method],
                    uri: log[uri],
                    headers: log[headers]
                )
            }
        } catch {
            print("Error fetching log entry by ID: \(error)")
        }
        return nil
    }

    private func shouldLogEntry(_ logEntry: LogEntry) -> Bool {
        printColored("Checking if log entry should be logged...", color: MAGENTA)
        let recentTimeLimit = Date().addingTimeInterval(-10)
        do {
            let recentLogs = try database.prepare(logTable
                .filter(ipAddress == logEntry.ipAddress && uri == logEntry.uri && timestamp > recentTimeLimit)
            )
            return recentLogs.makeIterator().next() == nil
        } catch {
            print("Error querying recent logs: \(error)")
            return true
        }
    }
}

struct LogEntry {
    let id: Int64
    let timestamp: Date
    let ipAddress: String
    let userAgent: String
    let referrer: String
    let method: String
    let uri: String
    let headers: String
}
