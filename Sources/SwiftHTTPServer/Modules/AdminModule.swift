//
//  AdminModule.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

class AdminModule: Module {
    init() {
        super.init(name: "admin")
        
        register(Route(routeUri: "/admin", requestHandler: { context in
            let content = TemplatePage(title: "Admin Home", body: "<h1>Admin Home</h1><p>$[date]</p><p><a href=\"/admin/users\">Users</a></p><p><a href=\"/admin/log\">Visit Log</a></p>")
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
        
        register(Route(routeUri: "/admin/log", requestHandler: { context in
            let logs = loggingMiddleware.getLogEntries()
            let logHtml = self.renderLogs(logs)
            let content = TemplatePage(title: "Visit Log", body: "<h1>Visit Log</h1>\(logHtml)<p><a href=\"/admin\">Admin Home</a></p>")
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
    }
    
    func renderLogs(_ logs: [LogEntry]) -> String {
        var html = """
        <table class="table">
            <tr><th>Date</th><th>IP Address</th><th>Method</th><th>URI</th><th>Referrer</th></tr>
        """
        
        for log in logs {
            html += """
            <tr>
                <td>\(log.timestamp)</td>
                <td>\(log.ipAddress)</td>
                <td>\(log.method.uppercased())</td>
                <td>\(log.uri)</td>
                <td>\(log.referrer)</td>
            </tr>
            """
        }
        
        html += "</table>"
        return html
    }
}
