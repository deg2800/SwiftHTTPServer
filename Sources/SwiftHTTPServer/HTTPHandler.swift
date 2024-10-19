import NIO
import NIOHTTP1
import Foundation

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

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
            printColored("Incoming request from \(YELLOW)\(request.headers["host"])\(RESET)", color: BLUE)
            printColored("User Agent: \(YELLOW)\(request.headers["user-agent"])\(RESET)", color: BLUE)

            switch request.method {
                case .GET:
                    printColored("Received \(YELLOW)GET\(BLUE) request:\(RESET) \(request.uri)", color: BLUE)
                case .POST:
                    printColored("Received \(YELLOW)POST\(BLUE) request:\(RESET) \(request.uri)", color: BLUE)
                case .PUT:
                    printColored("Received \(YELLOW)PUT\(BLUE) request:\(RESET) \(request.uri)", color: BLUE)
                case .DELETE:
                    printColored("Received \(YELLOW)DELETE\(BLUE) request:\(RESET) \(request.uri)", color: BLUE)
                default:
                    break
            }
            handleRequest(uri: request.uri, context: context)
            
        case .body:
            break
        
        case .end:
            break
        }
    }

    func handleRequest(uri: String, context: ChannelHandlerContext) {
        let filePath = getFilePath(for: uri)

        if let html = try? String(contentsOfFile: filePath, encoding: .utf8) {
            let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
            let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            
            printColored("Sending response: \(responseHead)", color: GREEN)
            
            let body = HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(string: html)))
            context.write(self.wrapOutboundOut(body), promise: nil)
            
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        } else {
            serve404(context: context)
        }
    }

    func getFilePath(for uri: String) -> String {
        var filePath = resourceDirectory + uri
        
        if uri.hasSuffix("/") {
            let indexHtmlPath = resourceDirectory + uri + "index.html"
            let indexHtmPath = resourceDirectory + uri + "index.htm"
            
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
        
        return filePath
    }

    func serve404(context: ChannelHandlerContext) {
        let errorFilePath = "\(resourceDirectory)/404.html"

        if let errorHtml = try? String(contentsOfFile: errorFilePath, encoding: .utf8) {
            let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
            let responseHead = HTTPResponseHead(version: .http1_1, status: .notFound, headers: headers)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            
            let body = HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(string: errorHtml)))
            context.write(self.wrapOutboundOut(body), promise: nil)
            printColored("Sending response: \(responseHead)", color: RED)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        } else {
            let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
            let responseHead = HTTPResponseHead(version: .http1_1, status: .notFound, headers: headers)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            
            let body = HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(string: "<html><body><h1>404 - Not Found</h1></body></html>")))
            context.write(self.wrapOutboundOut(body), promise: nil)
            printColored("Sending response: \(responseHead)", color: RED)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        printColored("Error: \(error)", color: RED)
        context.close(promise: nil)
    }
}
