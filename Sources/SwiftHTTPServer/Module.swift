//
//  Module.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import Foundation

class Module {
    let name: String
    var routes: [Route] = []
    
    init(name: String) {
        self.name = name
    }
    
    func register(_ route: Route) {
        routes.append(route)
    }
}
