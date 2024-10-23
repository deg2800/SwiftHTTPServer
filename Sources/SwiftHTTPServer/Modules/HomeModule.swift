//
//  HomeModule.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/21/24.
//

class HomeModule: Module {
    init() {
        super.init(name: "home")
        
        register(Route(routeUri: "/", requestHandler: { context in
            let content = TemplatePage(title: "Welcome", body: "<h1>Welcome</h1><p>This server is up and running!</p>")
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        }))
    }
}
