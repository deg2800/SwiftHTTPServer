# SwiftHTTPServer

### A Simple HTTP Server Built with Swift

**Version 1.0.5**  
Runs on macOS and Linux - Requires Swift 5.4

SwiftHTTPServer was my own project to dive deeper into creating command-line tools and building servers using Swift.

Originally, this server was a straightforward setup meant to serve HTML files and assets from a resources directory over a specified port using basic HTTP requests and responses.

## Features

I've been gradually adding a routing system. It allows you to register routes with modules, and then register these modules with a module manager. When the server starts, the module manager registers all routes with the router. Requests coming into the HTTP handler are directed to the router, which applies middleware before handling the route. If the requested URI matches a route, the router calls the route’s handler. If it doesn’t find a route, the router then tries to locate a static HTML or resource file (.jpg, .png, .gif, .css) in the resources directory. If neither a route nor a static file is found, the HTTP handler returns a 404 error page. The server’s default port is **8888**.

At some point, I’d like to add native SSL support, but for now, if you need SSL, you can use a reverse proxy with Apache or Nginx.

---

## Installation

### macOS

On macOS, if Xcode is installed, you likely already have the Swift command line tools. Run `swift --version` in Terminal; if the version displays, you're all set. The server is also configured to use SQLite, which should already be installed. You can verify by running `sqlite3 --version`.

### Linux

On Linux, you’ll need Swift installed and added to your PATH. Instructions specific to your distro can be found at [swift.org](https://swift.org). Run `swift --version` to confirm Swift is set up. You’ll also need to install `libsqlite3-dev`, or SwiftNIO won't compile. Once Swift and SQLite are ready, you’re good to proceed.

---

## Setup

1. **Clone the repository** and run:
   ```bash
   sudo ./build_server.sh
   ```

   If you get a permission error, make the script executable with:
   ```bash
   chmod +x build_server.sh
   ```

2. **Specify Resource Directory**: When prompted, choose a location for resources, defaulting to `/var/www/SwiftHTTPServer`. Files in the project’s `Resources` directory will be copied here. This is where the server will serve files from.

3. **Install**: Once built, the server will move to `/usr/local/bin/SwiftHTTPServer` and will be symlinked to `/usr/bin/SwiftHTTPServer`.

4. **Run the Server**: Start it on the default port with:
   ```bash
   SwiftHTTPServer run
   ```
   This will start the server on port 8888 and show log output for incoming requests. To view it, go to `http://localhost:8888` on the same machine. From other devices on the network, you can use the local IP if the firewall allows connections on port 8888.

5. **Custom Port**: Use `-p` or `--port` to specify a different port:
   ```bash
   SwiftHTTPServer run -p 8505
   ```
   Then, use this port instead of 8888 in your browser.

6. **View Registered Routes**: Running `SwiftHTTPServer routes` shows all routes in registered modules. I’ll add more documentation on modules later, but for now, you can look at the examples I’ve created. `AdminUsersModule` shows different routes handling SQLite CRUD operations and both GET and POST requests. You can register modules in `main.swift` by initializing `ModuleManager` with `moduleManager.registerModule([ModuleName]())`.

---

## Making the Server Internet Accessible

If you want to make this server accessible online, I recommend using a reverse proxy like Nginx or Apache, as SwiftHTTPServer currently only supports HTTP. I may write a guide on setting up a reverse proxy if there’s interest, but a quick Google search should also point you in the right direction.

**Important**: Right now, the server includes a dummy database with sample user data, and anyone can add to it. The `/admin` route is entirely open and public, including `/admin/log`, which logs the IP addresses of each request. To restrict access, you can:

- Modify route registration in each module and set `protected` to true to show an access-denied page for those routes.
- Remove module registrations in `main.swift` to disable all routes from a module.
- Write custom authentication middleware and register it with the middleware manager in `main.swift`.

It's your server, so feel free to experiment and customize it to your needs!

--- 

Enjoy using SwiftHTTPServer, and thanks for checking it out!
