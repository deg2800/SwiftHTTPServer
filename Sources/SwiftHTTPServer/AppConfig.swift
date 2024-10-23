//
//  AppConfig.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import Foundation

struct AppConfig: Codable {
    let environment: String
    let version: String
    let custom404: Bool
    let handleTrailingSlash: Bool
    
    static let defaultData: AppConfig = .init(environment: "development", version: "Unknown", custom404: false, handleTrailingSlash: false)
}

extension AppConfig {
    static func loadData(_ path: String) -> AppConfig {
        let url = URL(fileURLWithPath: path)
        let defaultData = AppConfig.defaultData

        guard let data = try? Data(contentsOf: url) else {
            return defaultData
        }
        
        let decoder = JSONDecoder()
        guard let decodedData = try? decoder.decode(AppConfig.self, from: data) else {
            return defaultData
        }
        
        return decodedData
    }
}
