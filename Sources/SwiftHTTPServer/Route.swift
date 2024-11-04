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
    private var middlewareManager: MiddlewareManager
    
    init(middlewareManager: MiddlewareManager) {
        self.middlewareManager = middlewareManager
    }
    
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
        
    func routeRequest(request: HTTPRequestHead, body: ByteBuffer?, context: ChannelHandlerContext) {
        let method = request.method
        let uri = request.uri
        let headers = request.headers
        
        let userAgent = headers["user-agent"].first ?? "Unknown User Agent"
        let referrer = headers["referer"].first ?? "Unknown Referrer"
        
        var parameters: [String: String] = [
            "method": method.rawValue,
            "uri": uri,
            "user-agent": userAgent,
            "referrer": referrer
        ]
        
        if let realIP = headers["X-Real-IP"].first {
            parameters["nginx-proxy-real-ip"] = realIP
        }
        
        for (headerName, headerValues) in headers {
            let headerValueString = headerValues.map(String.init).joined(separator: "")
            parameters[headerName.lowercased()] = headerValueString
        }

        let contextWrapper = ContextWrapper(context: context, parameters: parameters)
        
        middlewareManager.applyMiddlewares(context: contextWrapper) { updatedContext in
            switch method {
            case .GET:
                self.handleGetRequest(uri: uri, context: updatedContext)
            case .POST:
                if let body {
                    self.handlePostRequest(uri: uri, body: body, context: updatedContext.context)
                } else {
                    self.handleGetRequest(uri: uri, context: updatedContext)
                }
            default:
                let errorMessage = "Unsupported HTTP method \(method)"
                httpHandler.sendHtmlResponse(html: errorMessage, isError: true, context: context)
            }
        }
    }
    
    private func handleGetRequest(uri: String, context: ContextWrapper) {
        if let route = routes[uri] {
            if route.protected {
                protectedHandler(context.context)
            } else {
                route.requestHandler(context)
            }
        } else {
            if handleDynamicRoute(uri: uri, context: context.context) { return }

            routeStaticFile(uri: uri, context: context.context)
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
        case "jpg", "jpeg", "png", "gif", "css":
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                let mimeType: String
                var fileType: String = ""
                
                switch fileExtension(for: filePath) {
                case "jpg", "jpeg":
                    mimeType = "image/jpeg"
                    fileType = "image"
                case "png":
                    mimeType = "image/png"
                    fileType = "image"
                case "gif":
                    mimeType = "image/gif"
                    fileType = "image"
                case "css":
                    mimeType = "text/css"
                    fileType = "css"
                default:
                    mimeType = "application/octet-stream"
                    fileType = "data"
                }
                
                printColored("Returning \(fileType) file \(CYAN)\(filePath)\(GREEN) for URI \(CYAN)\(uri)", color: GREEN)
                httpHandler.sendBinaryResponse(data: fileData, mimeType: mimeType, context: context)
            } else {
                httpHandler.serve404(uri: uri, context: context)
            }

        default:
            httpHandler.serve404(uri: uri, context: context)
        }
    }
}
