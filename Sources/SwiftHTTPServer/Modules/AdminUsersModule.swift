//
//  AdminUsersModule.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import NIO
import NIOHTTP1
import SQLite
import Foundation


class AdminUsersModule: Module {
    var users: [User] = []
    
    init() {
        super.init(name: "admin/users")
        
        // Route for listing all users
        register(Route(routeUri: "/admin/users", protected: false, requestHandler: { context in
            do {
                self.users = try self.getUsers()
                let userTable = self.renderUsersTable()
                
                let content = TemplatePage(title: "Users Admin", body: """
                    <h1>Users List</h1>
                    <p><a href="/admin/users/add">Add User</a></p>
                    \(userTable)
                    <p><a href="/admin">Back to admin home</a></p>
                """)
                
                let html = content.render()
                httpHandler.sendHtmlResponse(html: html, context: context.context)
            } catch {
                //httpHandler.sendErrorResponse(context: context, error: error)
            }
        })) // "/admin/users"
        
        // Route for adding a user
        register(Route(routeUri: "/admin/users/add", protected: false, requestHandler: { context in
            if context.parameters["method"] == "POST" {
                print("POST request received")
                guard let bodyData = context.body else {
                    httpHandler.sendHtmlResponse(html: "<h1>Error</h1><p>No body data received</p>", isError: true, context: context.context)
                    return
                }
                self.handleUserPostRequest(context.context, bodyData: bodyData)
                return
            }
            let content = TemplatePage(title: "Add User", body: """
                <h1>Add User</h1>
                <form action="/admin/users/add" method="post">
                    <div class="form-group">
                        <label for="username">Username:</label>
                        <input type="text" class="form-control" name="username" id="username" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password:</label>
                        <input type="password" class="form-control" name="password" id="password" required>
                    </div>
                    <div class="form-check">
                        <input type="checkbox" class="form-check-input" name="isAdmin" id="isAdmin">
                        <label class="form-check-label" for="isAdmin">Is Admin</label>
                    </div>
                    <button type="submit" class="btn btn-primary">Add User</button>
                </form>
                <p><a href="/admin/users">Back to user list</a></p>
            """)
            
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        })) // "/admin/users/add"
        
        // Route for getting a user's info (dynamic)
        register(Route(routeUri: "/admin/users/:id", protected: false, dynamic: true, requestHandler: { context in
            
            let id = context.parameters["id"] ?? ""
            let userId = Int(id) ?? 0
            printColored("User ID: \(userId)", color: CYAN)
            
            var content: TemplatePage
            
            if id.isEmpty {
                printColored("ID Empty", color: RED)
                content = TemplatePage(title: "Get User", body: """
                <h1>Get User</h1>
                <p>ID Empty</p>
                <p><a href="/admin/users">Back to user list</a></p>
            """)

            } else {
                if let user = self.getUser(id: userId) {
                    content = TemplatePage(title: "Get User", body: """
                    <h1>Get User</h1>
                    <p>ID: \(user.id)</p>
                    <p>Username: \(user.username)</p>
                    <p>Is Admin: \(user.isAdmin ? "Yes" : "No")</p>
                    <p><a href="/admin/users/edit/\(user.id)">Edit user</a></p>
                    <p><a href="/admin/users/delete/\(user.id)">Delete user</a></p>
                    <p><a href="/admin/users">Back to user list</a></p>
                """)
                } else {
                    content = TemplatePage(title: "Get User", body: """
                <h1>Get User</h1>
                <p>ID \(id) not found</p>
                <p><a href="/admin/users">Back to user list</a></p>
                """)
                }
            }
            
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        })) // "/admin/users/:id"
        
        // Route for editing a user (dynamic)
        register(Route(routeUri: "/admin/users/edit/:id", protected: false, dynamic: true, requestHandler: { context in
            let id = context.parameters["id"] ?? ""
            let userId = Int(id) ?? 0
            printColored("User ID: \(userId)", color: CYAN)

            if context.parameters["method"] == "POST" {
                guard let bodyData = context.body else {
                    httpHandler.sendHtmlResponse(html: "<h1>Error</h1><p>No body data received</p>", isError: true, context: context.context)
                    return
                }
                self.handleUserPostRequest(context.context, bodyData: bodyData, edit: true, userId: Int64(userId))
                return
            }
                        
            var content: TemplatePage
            
            if id.isEmpty {
                printColored("ID Empty", color: RED)
                content = TemplatePage(title: "Get User", body: """
                <h1>Edit User</h1>
                <p>ID Empty</p>
                <p><a href="/admin/users">Back to user list</a></p>
            """)

            } else {
                if let user = self.getUser(id: userId) {
                    let isAdmin = user.isAdmin ? "checked" : ""
                    content = TemplatePage(title: "Get User", body: """
                <h1>Edit User</h1>
                <p>User ID: \(user.id)</p>
                <p>Created at: \(user.createdAt)</p>
                <form action="/admin/users/edit/\(user.id)" method="post">
                    <div class="form-group">
                        <label for="username">Username:</label>
                        <input type="text" class="form-control" name="username" id="username" value="\(user.username)" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password:</label>
                        <input type="password" class="form-control" name="password" id="password" value="\(user.password)" required>
                    </div>
                    <div class="form-check">
                        <input type="checkbox" class="form-check-input" name="isAdmin" id="isAdmin" \(isAdmin)>
                        <label class="form-check-label" for="isAdmin">Is Admin</label>
                    </div>
                    <input type="hidden" id="id" name="id" value="\(user.id)">
                    <button type="submit" class="btn btn-primary">Edit User</button>
                </form>
                <p><a href="/admin/users/\(user.id)">Cancel changes & return to user</a></p>
                <p><a href="/admin/users">Back to user list</a></p>
                """)
                } else {
                    content = TemplatePage(title: "Get User", body: """
                <h1>Edit User</h1>
                <p>ID \(id) not found</p>
                <p><a href="/admin/users">Back to user list</a></p>
                """)
                }
            }
            
            let html = content.render()
            httpHandler.sendHtmlResponse(html: html, context: context.context)
        })) // "/admin/users/edit/:id"
        
        // Route for deleting a user (dynamic)
        register(Route(routeUri: "/admin/users/delete/:id", protected: false, dynamic: true, requestHandler: { context in
            let id = context.parameters["id"] ?? ""
            let userId = Int64(id) ?? 0
            printColored("User ID: \(userId)", color: CYAN)

            do {
                try self.deleteUser(userId: userId)
            } catch {
                httpHandler.errorCaught(context: context.context, error: error)
            }
            
            httpHandler.redirect(to: "/admin/users", context: context.context)
        })) // "/admin/users/delete/:id"
        
        // Initialize the user table and create dummy data if necessary
        do {
            try createTable()
            try createDummyUsers()
            users = try getUsers()
        } catch {
            printColored("Error initializing AdminUsersModule: \(error)", color: RED)
        }
    }

    // SQLite table schema for users
    let table = Table("users")
    let id = SQLite.Expression<Int64>("id")
    let username = SQLite.Expression<String>("username")
    let password = SQLite.Expression<String>("password")
    let isAdmin = SQLite.Expression<Bool>("is_admin")
    let createdAt = SQLite.Expression<Date>("created_at")
    
    // Create users table in the database
    func createTable() throws {
        try database.conn.run(table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(username, unique: true)
            t.column(password)
            t.column(isAdmin, defaultValue: false)
            t.column(createdAt)
        })
    }
    
    // Create dummy users for the development environment
    func createDummyUsers() throws {
        if config.environment == "development" {
            printColored("Development environment", color: YELLOW)
            
            let dummyUsers = [
                ("admin", "admin", true),
                ("user", "user", false),
                ("user2", "user2", false),
                ("user3", "user3", false)
            ]
            
            guard try getUsers().isEmpty else { return }
            printColored("Inserting dummy users into the database", color: YELLOW)
            for (username, password, isAdmin) in dummyUsers {
                try database.conn.run(table.insert(self.username <- username, self.password <- password, self.isAdmin <- isAdmin, self.createdAt <- Date()))
            }
        }
    }
    
    // Fetch all users from the database
    func getUsers() throws -> [User] {
        var userList: [User] = []
        let users = try database.conn.prepare(table)
        for user in users {
            let id = try user.get(self.id)
            let username = try user.get(self.username)
            let password = try user.get(self.password)
            let isAdmin = try user.get(self.isAdmin)
            let createdAt = try user.get(self.createdAt)
            
            userList.append(User(id: Int(id), username: username, password: password, isAdmin: isAdmin, createdAt: createdAt))
        }
        return userList
    }
    
    func getUser(id: Int) -> User? {
        if let user = users.first(where: { $0.id == id }) {
            return user
        } else {
            return nil
        }
    }
    
    func createUser(username: String, password: String, isAdmin: Bool) throws {
        do {
            if try database.conn.run(table.insert(or: .replace, self.username <- username, self.password <- password, self.isAdmin <- isAdmin, createdAt <- Date())) > 0 {
                printColored("Added user \(username).", color: GREEN)
                users = try getUsers()
            } else {
                printColored("User \(username) not inserted.", color: RED)
            }
        } catch {
            printColored("Failed to add user \(username).", color: RED)
        }
    }
    
    func updateUser(userId: Int64, changeUsername: String, changePassword: String, changeIsAdmin: Bool) throws {
        let user = getDatabaseRow(userId)
        do {
            if try database.conn.run(user.update(username <- changeUsername, password <- changePassword, isAdmin <- changeIsAdmin)) > 0 {
                printColored("Updated user with ID \(userId).", color: GREEN)
                users = try getUsers()
            } else {
                printColored("User with ID \(userId) not found.", color: RED)
            }
        } catch {
            printColored("Failed to update user with ID \(userId).", color: RED)
        }
    }
    
    func deleteUser(userId: Int64) throws {
        let user = getDatabaseRow(userId)
        do {
            if try database.conn.run(user.delete()) > 0 {
                printColored("Deleted user with ID \(userId).", color: GREEN)
                users = try getUsers()
            } else {
                printColored("User with ID \(userId) not found.", color: RED)
            }
        }
    }
    
    func getDatabaseRow(_ ID: Int64) -> Table {
        return table.filter(id == ID)
    }
    
    // Render the users as an HTML table
    func renderUsersTable() -> String {
        guard !users.isEmpty else { return "<p>No users found.</p>" }
        
        var html = """
        <table class="table">
            <tr><th>ID</th><th>Username</th><th>Is Admin</th><th>Created At</th><th>Delete</th></tr>
        """
        
        for user in users {
            html += """
            <tr>
                <td><a href=\"/admin/users/\(user.id)\">\(user.id)</a></td>
                <td>\(user.username)</td>
                <td>\(user.isAdmin ? "Yes" : "No")</td>
                <td>\(user.createdAt)</td>
                <td><a href="/admin/users/delete/\(user.id)">Delete user</a></td>
            </tr>
            """
        }
        
        html += "</table>"
        return html
    }
    
    func handleUserPostRequest(_ context: ChannelHandlerContext, bodyData: ByteBuffer, edit: Bool = false, userId: Int64? = nil) {
        let formData = httpHandler.parseFormData(bodyData)
        
        if let formUsername = formData["username"], let formPassword = formData["password"] {
            
            let formIsAdmin = formData["isAdmin"] ?? ""
            var formIsAdminBool: Bool {
                return !formIsAdmin.isEmpty
            }
            
            do {
                if edit, let id = userId {
                    try updateUser(userId: id, changeUsername: formUsername, changePassword: formPassword, changeIsAdmin: formIsAdminBool)
                } else {
                    try createUser(username: formUsername, password: formPassword, isAdmin: formIsAdminBool)
                }
            } catch {
                httpHandler.errorCaught(context: context, error: error)
            }
            
            printColored("Received user created/updated form data", color: GREEN)
        } else {
            printColored("Error: Missing form data", color: RED)
        }
        
        let id = String(userId ?? 0)
        httpHandler.redirect(to: edit ? "/admin/users/\(id)" : "/admin/users", context: context)
    }

}

// Struct to represent a user
struct User {
    let id: Int
    let username: String
    let password: String
    let isAdmin: Bool
    let createdAt: Date
}
