
# Changelog

## [1.0.5] - 2024-11-05
### Added
- **AdminLogModule.swift**: New module for managing and viewing logs in the admin interface.
- **HTTPHandler.swift**: Introduced non-blocking file I/O with NIOThreadPool for improved file serving performance.

### Changed
- **Server.swift**: Increased server backlog from 256 to 1024 to handle higher connection loads.
- **AdminModule.swift**: Refactored log functionality, moving it to AdminLogModule.
- **config.json**: Updated version to 1.0.5.

## [1.0.4] - 2024-11-03
### Added
- **AdminLogModule.swift**: New module for managing and viewing logs in the admin interface.
- **HTTPHandler.swift**: Introduced non-blocking file I/O with NIOThreadPool for improved file serving performance.

### Changed
- **Server.swift**: Increased server backlog from 256 to 1024 to handle higher connection loads.
- **AdminModule.swift**: Refactored log functionality, moving it to AdminLogModule.
- **config.json**: Updated version to 1.0.5.

## [1.0.4] - 2024-11-03
### Added
- **LoggingMiddleware.swift**: Added SQLite logging support.
- **AdminModule.swift**: Log pagination and detailed view options added to the admin interface.
- **Resources/css/main.css**: Introduced CSS for `.user-header`, `.button`, `.table`, `.tile`, `.sidebar`, and responsive layouts.
- **README.md**: Added installation instructions for macOS and Linux.

### Changed
- **Router.swift**: Updated headers processing and `.css` handling in static file handler.
- **Template.swift**: Updated to use `main.css`.
- **AdminUsersModule.swift**: Breadcrumb navigation added.
- **HTTPHandler.swift**: Enhanced logging output with request details.

### Fixed
- **config.json**: Updated `version` to `1.0.4`.
- **main.swift**: Switched to SQLite-based logging middleware.

## [1.0.3] - 2024-10-25
### Added
- **Middleware.swift**: Introduced Middleware and MiddlewareManager classes.
- **LoggingMiddleware.swift**: Added file-based logging middleware with log rotation.

### Changed
- **README.md**: Added guidance for using a reverse proxy for internet accessibility.

### Fixed
- **config.json**: Updated `version` to `1.0.3`.
- **build_server.sh**: Fixed permissions and recursive resource copying.

## [1.0.2] - 2024-09-15
### Added
- **AdminModule.swift**: Admin page with user list.

### Changed
- **Route.swift**: Implemented `ContextWrapper` for request handling.

### Fixed
- General performance and stability improvements.

## [1.0.1] - 2024-08-20
### Added
- **README.md**: Basic project setup instructions.

### Changed
- Initial setup and project structure improvements.

## [1.0.0] - 2024-08-01
### Added
- Initial release of `SwiftHTTPServer`.
