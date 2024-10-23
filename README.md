#  SwiftHTTPServer

### A simple HTTP server written in Swift

Runs on macOS and Linux - Requires Swift 5.4

I created SwiftHTTPServer to better understand command line tool creation and how to build servers using Swift.

Originally, SwiftHTTPServer was built simply to serve html files and assets from a resources directory on a given port using standard HTTP requests/responses. 

I have been working on a routing system that relies on registering routes with modules, and registering modules with the module manager. On server startup, the module manager registers all module routes with the router. When requests come in to the HTTP Handler, it is sent to the router. If a route is found matching the requested URI, the router runs the route's handler. If a route is not found, the router next attempts to locate a static html or image (.jpg, .png, .gif) file in the resources directory. If no route or static file is found, the HTTP Handler sends a 404 error page. The default port of the server is **8888**

I'd like to add native SSL to the server in the future, but for now you can set up a proxy with a web server that supports SSL reverse proxy, such as Apache or Nginx.

#### Instructions

Clone this repo and run `sudo ./build_server.sh`. If you receive a permission error, the script may not be executable. Run `chmod +x build_server.sh` to make the script executable, and run `sudo ./build_server.sh` again.

You will be asked for a resource location, which will default to `/var/www/SwiftHTTPServer`. Any files in the project Resources directory will be copied here and this is where the running server will serve files from.

Once the server application has been built, it is moved to `/usr/local/bin/SwiftHTTPServer` and symlinked to `/usr/bin/SwiftHTTPServer`. 

You can now run the server by typing `SwiftHTTPServer run`. This will start the server on port 8888 and begin a log output showing all incoming requests. If you are running the server on macOS or Linux with a desktop environment, you can view the website on the computer the server is running on by going to `http://localhost:8888` in your browser. Instead of localhost, you can use your local IP address from other devices on your local network as long as the firewall on the server is configured to allow connections on port 8888. 

Alternatively, you can run `SwiftHTTPServer run -p [port]` or `SwiftHTTPServer run --port [port]` to begin the server on a different port. For example, `SwiftHTTPServer run -p 8505` begins the server on port 8505. You would then use this port instead of 8888 in your browser.

Running `SwiftHTTPServer routes` will display a list of all registered routes found in registered modules. I intend on documenting how modules work, but for now, you can copy the modules I have created as a guide. `AdminUsersModule` shows different routes handling SQLite CRUD operations and handling both GET and POST HTTP requests. Register modules in `main.swift` after initializing the `ModuleManager` by calling `moduleManager.registerModule([ModuleName]())`. 

If you've gotten to this point and now wish to make this server *internet accessible*, I would recommend using a reverse proxy with something like Nginx or Apache, as this server is HTTP, not HTTPS. If there is a demand for it, I may write a guide for it, otherwise a quick search on Google should point you in the right direction.
