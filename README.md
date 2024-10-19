#  SwiftHTTPServer

### A simple HTTP server written in Swift

Runs on macOS and Linux - Requires Swift 5.4

I created SwiftHTTPServer to better understand command line tool creation and how to build servers using Swift.

Right now, SwiftHTTPServer is built to serve html files and assets from a resources directory on a given port using standard HTTP requests/responses. The default port is **8888**

I'd like to add native SSL to the server in the future, but for now you can set up a proxy with a web server that supports SSL reverse proxy, such as Apache or Nginx.

#### Instructions

Clone this repo and run `sudo ./build_server.sh`. If you receive a permission error, the script may not be executable. Run `chmod +x build_server.sh` to make the script executable, and run `sudo ./build_server.sh` again.

You will be asked for a resource location, which will default to `/var/www/SwiftHTTPServer`. Any files in the project Resources directory will be copied here and this is where the running server will serve files from.

Once the server application has been built, it is moved to `/usr/local/bin/SwiftHTTPServer` and symlinked to `/usr/bin/SwiftHTTPServer`. 

You can now run the server by typing `SwiftHTTPServer run`. This will start the server on port 8888 and begin a log output showing all incoming requests. If you are running the server on macOS or Linux with a desktop environment, you can view the website on the computer the server is running on by going to `http://localhost:8888` in your browser. Instead of localhost, you can use your local IP address from other devices on your local network as long as the firewall on the server is configured to allow connections on port 8888. 

Alternatively, you can run `SwiftHTTPServer run -p [port]` or `SwiftHTTPServer run --port [port]` to begin the server on a different port. For example, `SwiftHTTPServer run -p 8505` begins the server on port 8505. You would then use this port instead of 8888 in your browser.

If you've gotten to this point and now wish to make this server *internet accessible*, I would recommend using a reverse proxy with something like Nginx or Apache, as this server is HTTP, not HTTPS. If there is a demand for it, I may write a guide for it, otherwise a quick search on Google should point you in the right direction.
