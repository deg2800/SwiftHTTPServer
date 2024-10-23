import NIO
import NIOHTTP1

func startServer(on port: Int) throws {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    defer {
        try? group.syncShutdownGracefully()
    }
        
    let bootstrap = ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelInitializer { channel in
            channel.pipeline.configureHTTPServerPipeline().flatMap {
                channel.pipeline.addHandler(httpHandler)
            }
        }
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

    let channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
    printColored("\(BOLD)SwiftHTTPServer \(MAGENTA)v\(config.version)", color: GREEN)
    printColored("Server running on port \(CYAN)\(port)", color: YELLOW)
    printColored("Press CTRL+C to stop the server", color: RED)
    printColored("=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=", color: RESET)
    
    try channel.closeFuture.wait()
}
