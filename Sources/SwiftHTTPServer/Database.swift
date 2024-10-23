//
//  Database.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//


import Foundation
import SQLite

class Database {
    let dbFile: String = "database.sqlite"
    let conn: Connection
    
    init() throws {
        do {
            self.conn = try Connection(dbFile)
        } catch {
            printColored("Error: \(error)", color: RED)
            throw error
        }
    }
}
