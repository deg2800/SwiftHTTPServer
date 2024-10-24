//
//  Middleware.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/23/24.
//

protocol Middleware {
    func handle(context: ContextWrapper, next: @escaping (ContextWrapper) -> Void)
}

class MiddlewareManager {
    private var middlewares: [Middleware] = []
    
    func use(_ middleware: Middleware) {
        middlewares.append(middleware)
    }
    
    func applyMiddlewares(context: ContextWrapper, completion: @escaping (ContextWrapper) -> Void) {
        applyMiddleware(at: 0, context: context, completion: completion)
    }
    
    private func applyMiddleware(at index: Int, context: ContextWrapper, completion: @escaping (ContextWrapper) -> Void) {
        if index < middlewares.count {
            let middleware = middlewares[index]
            middleware.handle(context: context) { newContext in
                self.applyMiddleware(at: index + 1, context: newContext, completion: completion)
            }
        } else {
            completion(context)
        }
    }
}
