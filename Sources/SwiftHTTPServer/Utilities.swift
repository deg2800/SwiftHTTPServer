import Foundation

// Color codes for terminal output
let RED = "\u{001B}[0;31m"
let GREEN = "\u{001B}[0;32m"
let YELLOW = "\u{001B}[0;33m"
let BLUE = "\u{001B}[0;34m"
let MAGENTA = "\u{001B}[0;35m"
let CYAN = "\u{001B}[0;36m"
let WHITE = "\u{001B}[0;37m"
let BOLD = "\u{001B}[1m"
let DIM = "\u{001B}[2m"
let UNDERSCORE = "\u{001B}[4m"
let BLINK = "\u{001B}[5m"
let INVERT = "\u{001B}[7m"
let HIDDEN = "\u{001B}[8m"
let SCROLLING = "\u{001B}[9m"
let RESET = "\u{001B}[0m"
let CLEAR = "\u{001B}[2J"
let HOME = "\u{001B}[H"
let END = "\u{001B}[F"
let SAVE_CURSOR = "\u{001B}[s"
let RESTORE_CURSOR = "\u{001B}[u"

func printColored(_ message: String, color: String) {
    print("\(color)\(message)\(RESET)")
}

// Parse command-line arguments
func parseArguments() -> (command: String, port: Int) {
    let arguments = CommandLine.arguments
    var port = 8888

    if arguments.count == 1 {
        showHelp()
    }

    guard arguments.contains("run") else {
        showHelp()
        exit(0)
    }

    if let portIndex = arguments.firstIndex(where: { $0 == "-p" || $0 == "--port" }), arguments.count > portIndex + 1 {
        if let customPort = Int(arguments[portIndex + 1]) {
            port = customPort
        } else {
            printColored("Invalid port number.", color: RED)
            exit(1)
        }
    }

    return (command: "run", port: port)
}

func showHelp() {
    print("""
    \(GREEN)Swift HTTP Server\(RESET)
    Usage: SwiftHTTPServer <command> [options]
    
    Commands:
      \(YELLOW)run           Starts the HTTP server\(RESET)
      -h, --help    Show this help message
    
    Options:
      -p, --port    Specify a custom port number (default is 8888)
    """)
    exit(0)
}
