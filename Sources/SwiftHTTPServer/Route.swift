//
//  Route.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import NIO
import NIOHTTP1
import Foundation

typealias RequestHandler = (ChannelHandlerContext) -> Void

struct RequestContext {
    let handler: (ContextWrapper) -> Void
    var parameters: [String: String]
}

struct ContextWrapper {
    let context: ChannelHandlerContext
    var parameters: [String: String]
    var body: ByteBuffer?
}

struct Route {
    let routeUri: String
    let protected: Bool
    let dynamic: Bool
    let method: HTTPMethod
    var requestContext: RequestContext
    
    var requestHandler: (ContextWrapper) -> Void {
        requestContext.handler
    }
    
    init(routeUri: String, protected: Bool = false, dynamic: Bool = false, method: HTTPMethod = .GET, requestHandler: @escaping (ContextWrapper) -> Void) {
        self.routeUri = routeUri
        self.protected = protected
        self.dynamic = dynamic
        self.method = method
        self.requestContext = RequestContext(handler: requestHandler, parameters: [:])
    }

}

class Router {
    private var routes: [String: Route] = [:]
    
    private let protectedHandler: RequestHandler = { context in
        let content = TemplatePage(title: "Protected", body: "<h1>Access Denied</h1><p>This page is protected</p><p><a href=\"/\">Back to site</a></p>")
        let html = content.render()
        httpHandler.sendHtmlResponse(html: html, context: context)
    }
        
    func registerRoute(_ route: Route) {
        routes[route.routeUri] = route
        if !route.routeUri.hasSuffix("/") && config.handleTrailingSlash {
            let newRoute = Route(routeUri: route.routeUri + "/", requestHandler: route.requestHandler)
            routes[newRoute.routeUri] = newRoute
        }
    }
        
    func routeRequest(uri: String, method: HTTPMethod, body: ByteBuffer?, context: ChannelHandlerContext) {
        switch method {
        case .GET:
            handleGetRequest(uri: uri, context: context)
        case .POST:
            if let body {
                handlePostRequest(uri: uri, body: body, context: context)
            } else {
                handleGetRequest(uri: uri, context: context)
            }
        default:
            let errorMessage = "Unsupported HTTP method \(method)"
            httpHandler.sendHtmlResponse(html: errorMessage, isError: true, context: context)
        }
    }
    
    private func handleGetRequest(uri: String, context: ChannelHandlerContext) {
        if let route = routes[uri] {
            if route.protected {
                protectedHandler(context)
            } else {
                route.requestHandler(ContextWrapper(context: context, parameters: [:]))
            }
        } else {
            if handleDynamicRoute(uri: uri, context: context) { return }

            routeStaticFile(uri: uri, context: context)
        }
    }
    
    private func handlePostRequest(uri: String, body: ByteBuffer, context: ChannelHandlerContext) {
        if let route = routes[uri] {
            if route.protected {
                protectedHandler(context)
            } else {
                route.requestHandler(ContextWrapper(context: context, parameters: ["method":"POST"], body: body))
            }
        } else {
            if handleDynamicRoute(uri: uri, context: context, body: body) {
                return
            } else {
                httpHandler.serve404(uri: uri, context: context)
            }
        }

    }
    
    private func checkIfDynamicRoute(uri: String, context: ChannelHandlerContext) -> (dynamic: Bool, route: Route?) {
        let path = uri.split(separator: "/").dropLast().joined(separator: "/")
        let variable = uri.split(separator: "/").last
        let dynamicPath = "/\(path)/:id"
        if let routeDict = routes.first(where: { $0.key.contains(dynamicPath) && $0.value.dynamic }) {
            var route = routeDict.value
            let varDict: [String: String] = ["id": String(variable ?? "")]
            route.requestContext.parameters = varDict
            printColored("Dynamic Route URI: \(route.routeUri)", color: CYAN)
            return (true, route)
        }
        
        return (false, nil)
    }
    
    private func handleDynamicRoute(uri: String, context: ChannelHandlerContext, body: ByteBuffer? = nil) -> Bool {
        let dynamic = checkIfDynamicRoute(uri: uri, context: context)
        if dynamic.dynamic, let dynamicRoute = dynamic.route {
            if let body {
                var dynamicPostRoute = dynamicRoute
                dynamicPostRoute.requestContext.parameters["method"] = "POST"
                dynamicPostRoute.requestHandler(ContextWrapper(context: context, parameters: dynamicPostRoute.requestContext.parameters, body: body))
            } else {
                dynamicRoute.requestHandler(ContextWrapper(context: context, parameters: dynamicRoute.requestContext.parameters))
            }
            return true
        } else {
            return false
        }
    }
    
    private func routeStaticFile(uri: String, context: ChannelHandlerContext) {
        func fileExtension(for filePath: String) -> String {
            return URL(fileURLWithPath: filePath).pathExtension.lowercased()
        }
        
        let filePath = httpHandler.getFilePath(for: uri)

        switch fileExtension(for: filePath) {
        case "html", "htm":
            if let html = try? String(contentsOfFile: filePath, encoding: .utf8) {
                printColored("Returning HTML file \(CYAN)\(filePath)\(GREEN) for URI \(CYAN)\(uri)", color: GREEN)
                httpHandler.sendHtmlResponse(html: html, context: context)
            } else {
                httpHandler.serve404(uri: uri, context: context)
            }

        case "jpg", "jpeg", "png", "gif":
            // Handle image files
            if let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                let mimeType: String
                switch fileExtension(for: filePath) {
                case "jpg", "jpeg":
                    mimeType = "image/jpeg"
                case "png":
                    mimeType = "image/png"
                case "gif":
                    mimeType = "image/gif"
                default:
                    mimeType = "application/octet-stream"
                }
                
                printColored("Returning image file \(CYAN)\(filePath)\(GREEN) for URI \(CYAN)\(uri)", color: GREEN)
                httpHandler.sendBinaryResponse(data: imageData, mimeType: mimeType, context: context)
            } else {
                httpHandler.serve404(uri: uri, context: context)
            }

        default:
            httpHandler.serve404(uri: uri, context: context)
        }
    }
}
