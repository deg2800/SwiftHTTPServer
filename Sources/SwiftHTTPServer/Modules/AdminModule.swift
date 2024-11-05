//
//  AdminModule.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import SQLite
import Foundation

class AdminModule: Module {
    
    init() {
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
        
    }
}
