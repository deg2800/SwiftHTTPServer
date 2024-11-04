import Foundation

let config = AppConfig.loadData("/etc/SwiftHTTPServer/config.json")
let middlewareManager = MiddlewareManager()
let router = Router(middlewareManager: middlewareManager)
let httpHandler = HTTPHandler(router: router)
let moduleManager = ModuleManager(router: router)
let database = try Database()

let loggingMiddleware = LoggingMiddleware(database: database.conn)
middlewareManager.use(loggingMiddleware)

moduleManager.registerModule(HomeModule())
moduleManager.registerModule(AdminModule(loggingMiddleware: loggingMiddleware))
moduleManager.registerModule(AdminUsersModule())

do {
    let (command, port) = parseArguments()
    if command == "run" {
        try startServer(on: port)
    } else if command == "routes" {
        printColored("Showing Registered Routes", color: GREEN)
        moduleManager.listRoutes()
    }
} catch {
    printColored("◊   ◊ |", color: RED)
    printColored(" ◊ ◊  |", color: RED)
    printColored("  ◊   | Error: \(error)", color: RED)
    printColored(" ◊ ◊  |", color: RED)
    printColored("◊   ◊ |", color: RED)
}
