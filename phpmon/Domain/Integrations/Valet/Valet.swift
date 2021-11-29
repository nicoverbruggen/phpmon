//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class Valet {
    
    var version: String
    var config: Valet.Configuration
    var detectedSites: [String]
    
    init() {
        self.version = Actions.valet("--version")
            .replacingOccurrences(of: "Laravel Valet ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/valet/config.json")
        
        self.config = try! JSONDecoder().decode(
            Valet.Configuration.self,
            from: try! String(contentsOf: file, encoding: .utf8).data(using: .utf8)!
        )
        
        /*
        print("PHP Monitor should scan the following paths:")
        print(self.config.paths)
        */
        
        self.detectedSites = []
    }
    
    // MARK: - Structs
    
    struct Configuration: Decodable {
        let tld: String
        let paths: [String]
        let loopback: String
    }
    
}
