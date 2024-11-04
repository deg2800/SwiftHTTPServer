//
//  AdminModule.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import SQLite
import Foundation

class AdminModule: Module {
    private let loggingMiddleware: LoggingMiddleware
    private let logTable = Table("logs")
    private let id = SQLite.Expression<Int64>("id")

    init(loggingMiddleware: LoggingMiddleware) {
        self.loggingMiddleware = loggingMiddleware
        super.init(name: "admin")
        
        register(Route(routeUri: "/admin", requestHandler: { context in
            let content = TemplatePage(title: "Admin Home", body: """
               <h1>Admin Home</h1>
               <p>$[date]</p>
               <div class="dashboard-tiles">
                   <div class="tile">
                       <blueTitle>Users</blueTitle>
                       <p><a href=\"/admin/users\"><button class="button">Users</button></a></p>
                   </div>
                   <div class="tile">
                       <blueTitle>Logs</blueTitle>
                       <p><a href=\"/admin/log\"><button class="button">Visit Log</button></a></p>
                   </div>
               </div>
               <br />
               """)
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
        
        register(Route(routeUri: "/admin/log", requestHandler: { context in
            let logs = self.loggingMiddleware.getLogEntries()
            let logHtml = self.renderLogs(logs, page: 1, pageSize: 20)
            let content = TemplatePage(title: "Visit Log", body: """
            <breadcrumb><a href=\"/admin\">Admin Home</a> > Visit Log</breadcrumb>
            <h1>Visit Log</h1>
            \(logHtml)
            <p></p>
            """)
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
        
        register(Route(routeUri: "/admin/log/page/:id", dynamic: true, requestHandler: { context in
            guard let pageStr = context.parameters["id"], let page = Int(pageStr) else {
                httpHandler.sendErrorResponse(context: context.context, message: "Invalid page number")
                return
            }
            
            let logs = self.loggingMiddleware.getLogEntries()
            let logHtml = self.renderLogs(logs, page: page, pageSize: 20)
            let content = TemplatePage(title: "Visit Log", body: """
            <breadcrumb><a href=\"/admin\">Admin Home</a> > Visit Log</breadcrumb>
            <h1>Visit Log</h1>
            \(logHtml)
            <p></p>
            """)
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
        
        register(Route(routeUri: "/admin/log/:id", dynamic: true, requestHandler: { context in
            guard let idStr = context.parameters["id"], let logId = Int64(idStr),
                  let log = self.loggingMiddleware.getLogEntry(by: logId) else {
                httpHandler.sendErrorResponse(context: context.context, message: "Log entry not found")
                return
            }
            
            let logHtml = self.renderLogDetail(log)
            let content = TemplatePage(title: "Log Details", body: """
                <breadcrumb><a href=\"/admin\">Admin Home</a> > <a href=\"/admin/log\">Visit Log</a> > Log Details</breadcrumb>
                <h1>Log Entry Details</h1>
                \(logHtml)
            """)
            
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))

        register(Route(routeUri: "/admin/log/delete/:id", dynamic: true, requestHandler: { context in
            guard let idStr = context.parameters["id"], let logId = Int64(idStr) else {
                httpHandler.sendErrorResponse(context: context.context, message: "Invalid log ID")
                return
            }

            do {
                try self.deleteLogEntry(logId)
                httpHandler.redirect(to: "/admin/log", context: context.context)
            } catch {
                httpHandler.sendErrorResponse(context: context.context, message: "Failed to delete log entry")
            }
        }))

        register(Route(routeUri: "/admin/log/delete/all", requestHandler: { context in
            do {
                try self.deleteAllLogEntries()
                httpHandler.redirect(to: "/admin/log", context: context.context)
            } catch {
                httpHandler.sendErrorResponse(context: context.context, message: "Failed to delete all log entries")
            }
        }))
    }
    
    func renderLogs(_ logs: [LogEntry], page: Int, pageSize: Int) -> String {
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, logs.count)
        
        guard startIndex < logs.count else {
            return "<p>No logs available for this page.</p>"
        }
        
        var html = """
        <table class="table">
            <tr><th>Date</th><th>IP Address</th><th>Method</th><th>URI</th><th>User Agent</th><th>Actions</th></tr>
        """
        
        for log in logs[startIndex..<endIndex] {
            html += """
            <tr>
                <td>\(log.timestamp)</td>
                <td>\(log.ipAddress)</td>
                <td>\(log.method.uppercased())</td>
                <td>\(log.uri)</td>
                <td>\(log.userAgent)</td>
                <td>
                    <p><a href="/admin/log/\(log.id)"><button class="button">View Details</button></a></p>
                    <p><a href="/admin/log/delete/\(log.id)"><button class="button-destructive">Delete</button></a></p>
                </td>
            </tr>
            """
        }
        
        html += "</table>"
        
        let totalPages = (logs.count + pageSize - 1) / pageSize
        html += "<div class='pagination'>"
        
        if page > 1 {
            html += "<a href='/admin/log/page/\(page - 1)'>&laquo; Previous</a>"
        }
        
        html += "<span> Page \(page) of \(totalPages) </span>"
        
        if page < totalPages {
            html += "<a href='/admin/log/page/\(page + 1)'>Next &raquo;</a>"
        }
        
        html += "</div>"

        html += """
        <p><a href="/admin/log/delete/all"><button class="button-destructive">Delete All Logs</button></a></p>
        """
        
        return html
    }
    
    func renderLogDetail(_ log: LogEntry) -> String {
        var html = """
        <p><strong>Date:</strong> \(log.timestamp)</p>
        <p><strong>IP Address:</strong> \(log.ipAddress)</p>
        <p><strong>Method:</strong> \(log.method.uppercased())</p>
        <p><strong>URI:</strong> \(log.uri)</p>
        <p><strong>User Agent:</strong> \(log.userAgent)</p>
        <h3>Headers</h3>
        <table class="table">
            <tr><th>Header</th><th>Value</th></tr>
        """
        
        if let headers = try? JSONSerialization.jsonObject(with: Data(log.headers.utf8), options: []) as? [String: String] {
            for (header, value) in headers {
                html += """
                <tr><td>\(header)</td><td>\(value)</td></tr>
                """
            }
        } else {
            html += "<tr><td colspan='2'>No headers available</td></tr>"
        }
        
        html += "</table>"
        
        return html
    }
    
    private func deleteLogEntry(_ logId: Int64) throws {
        let logToDelete = logTable.filter(id == logId)
        try loggingMiddleware.database.run(logToDelete.delete())
    }

    private func deleteAllLogEntries() throws {
        try loggingMiddleware.database.run(logTable.delete())
    }
}
