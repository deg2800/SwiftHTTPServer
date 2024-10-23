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
            let content = TemplatePage(title: "Admin Home", body: "<h1>Admin Home</h1><p>$[date]</p><p><a href=\"/admin/users\">Users</a></p>")
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
    }
}
