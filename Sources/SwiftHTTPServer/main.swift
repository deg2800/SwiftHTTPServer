import Foundation

let config = AppConfig.loadData("/etc/SwiftHTTPServer/config.json")
let router = Router()
let httpHandler = HTTPHandler(router: router)
let moduleManager = ModuleManager(router: router)
let database = try Database()

moduleManager.registerModule(HomeModule())
moduleManager.registerModule(AdminModule())
moduleManager.registerModule(AdminUsersModule())

do {
    //print("\(CLEAR)")
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
