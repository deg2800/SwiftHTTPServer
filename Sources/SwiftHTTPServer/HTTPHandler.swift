import NIO
import NIOHTTP1
import Foundation
import SQLite

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var accumulatedBody: ByteBuffer?
    private var currentRequest: HTTPRequestHead?
    
    let router: Router
    
    init(router: Router) {
        self.router = router
    }

    var resourceDirectory: String {
        var resDir = "/var/www/SwiftHTTPServer"
        var envVarFound = false
        
        if let resDirEnvironmentVariable = ProcessInfo.processInfo.environment["RESOURCES_DIR"] {
            resDir = resDirEnvironmentVariable
            envVarFound = true
        }

        switch envVarFound {
        case true:
            printColored("Resource directory found in environment: \(CYAN)\(resDir)", color: GREEN)
        case false:
            printColored("Resource directory not found in environment. Defaulting to \(CYAN)\(resDir)", color: RED)
        }
        return resDir
    }


    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        switch reqPart {
        case .head(let request):
            print(" ")
            printColored("=*=*=*=*= \(YELLOW)\(UNDERSCORE)New Request\(RESET)\(MAGENTA) =*=*=*=*=", color: MAGENTA)
            printColored("Processing channel read in HTTPHandler", color: BLUE)
            var ipAddress: String = ""
            let nginxProxyRealIP = request.headers["X-Real-IP"]
            if !nginxProxyRealIP.isEmpty {
                printColored("↳ Found X-Real-IP header. Getting real IP from header", color: BLUE)
                ipAddress = nginxProxyRealIP.joined()
            } else {
                ipAddress = "\(context.remoteAddress?.ipAddress ?? "Unknown")"
                printColored("↳ No X-Real-IP header found", color: BLUE)
            }
            printColored("↳ Incoming request from \(YELLOW)\(ipAddress)\(RESET)", color: BLUE)
            printColored("↳ User Agent: \(YELLOW)\(request.headers["user-agent"])\(RESET)", color: BLUE)
            printColored("↳ Referrer: \(YELLOW)\(request.headers["referer"])\(RESET)", color: BLUE)
            
            currentRequest = request
            accumulatedBody = nil

            switch request.method {
                case .GET:
                    printColored("↳ Handling \(YELLOW)GET\(BLUE) request:\(CYAN) \(request.uri)", color: BLUE)
                case .POST:
                    printColored("↳ Handling \(YELLOW)POST\(BLUE) request:\(CYAN) \(request.uri)", color: BLUE)
                    accumulatedBody = ByteBuffer()
                case .PUT:
                    printColored("↳ Handling \(YELLOW)PUT\(BLUE) request:\(CYAN) \(request.uri)", color: BLUE)
                case .DELETE:
                    printColored("↳ Handling \(YELLOW)DELETE\(BLUE) request:\(CYAN) \(request.uri)", color: BLUE)
                default:
                    break
            }
        case .body(let byteBuffer):
            accumulatedBody = byteBuffer
        case .end:
            guard let request = currentRequest else { return }
            let body = accumulatedBody
            
            router.routeRequest(request: request, body: body, context: context)
            
            accumulatedBody = nil
            currentRequest = nil
        }
    }

    func redirect(to uri: String, context: ChannelHandlerContext) {
        printColored("↳ Redirecting to: \(CYAN)\(uri)", color: GREEN)
        let headers = HTTPHeaders([("Location", uri)])
        let responseHead = HTTPResponseHead(version: .http1_1, status: .seeOther, headers: headers)
        
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil)), promise: nil)
        context.flush()
    }

    func parseFormData(_ bodyData: ByteBuffer) -> [String: String] {
        let bodyString = bodyData.getString(at: 0, length: bodyData.readableBytes) ?? ""
        var formData: [String: String] = [:]
        let keyValuePairs = bodyString.split(separator: "&")
        
        for pair in keyValuePairs {
            let components = pair.split(separator: "=")
            if components.count == 2 {
                let key = String(components[0]).removingPercentEncoding ?? ""
                let value = String(components[1]).removingPercentEncoding ?? ""
                formData[key] = value
            }
        }
        return formData
    }
    
    func sendHtmlResponse(html: String, isError: Bool = false, status: HTTPResponseStatus = .ok, context: ChannelHandlerContext) {
        let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
        let responseHead = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        
        printColored("Sending HTML response: \(responseHead)", color: isError ? RED : GREEN)
        
        let body = HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(string: html)))
        context.write(self.wrapOutboundOut(body), promise: nil)
        
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    func sendBinaryResponse(data: Data, mimeType: String, status: HTTPResponseStatus = .ok, context: ChannelHandlerContext) {
        let headers = HTTPHeaders([("content-type", mimeType),
                                   ("content-length", "\(data.count)")])
        let responseHead = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        
        printColored("Sending binary response: \(responseHead)", color: GREEN)

        var buffer = context.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        
        let body = HTTPServerResponsePart.body(.byteBuffer(buffer))
        context.write(self.wrapOutboundOut(body), promise: nil)
        
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    func getFilePath(for uri: String) -> String {
        var filePath = resourceDirectory + uri
        
        if uri.hasSuffix("/") {
            let indexHtmlPath = filePath + "index.html"
            let indexHtmPath = filePath + "index.htm"
            
            if FileManager.default.fileExists(atPath: indexHtmlPath) {
                filePath = indexHtmlPath
            } else if FileManager.default.fileExists(atPath: indexHtmPath) {
                filePath = indexHtmPath
            }
        } else {
            if !uri.contains(".") {
                filePath += ".html"
            }
        }
        printColored("File path: \(filePath)", color: CYAN)
        return filePath
    }

    func serve404(uri: String = "", context: ChannelHandlerContext) {
        let errorFilePath = "\(resourceDirectory)/404.html"

        if let errorHtml = try? String(contentsOfFile: errorFilePath, encoding: .utf8), config.custom404 {
            sendHtmlResponse(html: errorHtml, isError: true, status: .notFound, context: context)
        } else {
            let errorHtml = TemplatePage(title: "404 - Not Found", body: "<h1>404 - Not Found</h1><p>The requested resource (\(uri)) could not be found.</p><p><a href=\"/\">Return to the home page</a></p>").render()
            sendHtmlResponse(html: errorHtml, isError: true, status: .notFound, context: context)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        printColored("Error: \(error)", color: RED)
        context.close(promise: nil)
    }
    
    func sendErrorResponse(context: ChannelHandlerContext, message: String, status: HTTPResponseStatus = .internalServerError) {
        let errorHtml = TemplatePage(title: "\(status.code) - Error", body: """
            <h1>\(status.code) - Error</h1>
            <p>\(message)</p>
            <p><a href=\"/\">Return to the home page</a></p>
        """).render()
        sendHtmlResponse(html: errorHtml, isError: true, status: status, context: context)
    }
}
