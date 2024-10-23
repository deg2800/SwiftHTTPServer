//
//  ModuleManager.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import Foundation

class ModuleManager {
    private var modules: [Module] = []
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    func registerModule(_ module: Module) {
        modules.append(module)
        module.routes.forEach {
            router.registerRoute($0)
        }
    }
    
    func listRoutes() {
        modules.forEach { module in
            module.routes.forEach { route in
                print("Module: \(module.name), Route: \(route.routeUri)\(route.dynamic ? " (dynamic)" : "")")
            }
        }
    }
}
