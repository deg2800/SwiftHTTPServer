import Foundation

do {
    let (command, port) = parseArguments()
    if command == "run" {
        try startServer(on: port)
    }
} catch {
    printColored("◊   ◊ |", color: RED)
    printColored(" ◊ ◊  |", color: RED)
    printColored("  ◊   | Error: \(error)", color: RED)
    printColored(" ◊ ◊  |", color: RED)
    printColored("◊   ◊ |", color: RED)
}
