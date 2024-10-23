//
//  File.swift
//  SwiftHTTPServer
//
//  Created by Derrick Goodfriend on 10/20/24.
//

import Foundation

struct TemplatePage {
    var title: String
    var body: String
    
    func render() -> String {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
            <title>\(title) - Swift HTTP Server</title>
        </head>
        <body>
        <nav class="navbar navbar-dark bg-primary border-bottom border-dark">
            <div class="container">
                <a class="navbar-brand" href="/">SwiftHTTPServer</a>
            </div>
        </nav>
        <div class="container mt-2">
        \(bodyWithTagsParsed())
        Server version \(config.version)
        </div>
        </body>
        </html>
        """
        return html
    }
    
    func bodyWithTagsParsed() -> String {
        let date = formatDateForPlatform(Date())
        let siteName = "Swift HTTP Server"
        
        let tags: [String: String] = [
            "date" : date,
            "siteName" : siteName
        ]
        
        var text = self.body
        for (key, value) in tags {
            text = replaceOccurrences(of: "$[\(key)]", with: value, in: text)
        }
        return text
    }
    
    func replaceOccurrences(of target: String, with replacement: String, in originalString: String) -> String {
        var newString = originalString
        while let range = newString.range(of: target) {
            newString.replaceSubrange(range, with: replacement)
        }
        return newString
    }
    
    func formatDateForPlatform(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.string(from: date)
    }
}
