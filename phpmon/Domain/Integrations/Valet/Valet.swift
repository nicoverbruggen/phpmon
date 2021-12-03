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
    var parkedSites: [Site] = []
    var linkedSites: [Site] = []
    
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
        
        print("PHP Monitor should scan the following paths:")
        print(self.config.paths)
        
        resolvePaths()
    }
    
    private func resolvePaths() {
        self.linkedSites = []
        self.parkedSites = []
        
        for path in self.config.paths {
            let entries = try! FileManager.default.contentsOfDirectory(atPath: path)
            for entry in entries {
                self.resolvePath(entry, forPath: path)
            }
        }
    }
    
    private func resolvePath(_ entry: String, forPath path: String) {
        let siteDir = path + "/" + entry
        
        // See if the file is a symlink, if so, resolve it
        let attrs = try! FileManager.default.attributesOfItem(atPath: siteDir)
        
        // We can also determine whether the thing at the path is a directory, too
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        if type == FileAttributeType.typeSymbolicLink {
            self.linkedSites.append(Site(aliasPath: siteDir))
        } else if type == FileAttributeType.typeDirectory {
            self.parkedSites.append(Site(absolutePath: siteDir))
        } else {
            print("The item at: `\(siteDir)` was neither a symlink nor a directory. Skipping.")
        }
    }
    
    // MARK: - Structs
    
    class Site {
        var name: String
        
        var absolutePath: String
        var aliasPath: String?
        
        init(absolutePath: String) {
            self.absolutePath = absolutePath
            self.aliasPath = nil
            self.name = URL(string: absolutePath)!.lastPathComponent
            self.detectSiteProperties()
        }
        
        convenience init(aliasPath: String) {
            // Resolve the symlink
            let absolutePath = try! FileManager.default
                .destinationOfSymbolicLink(atPath: aliasPath)
            self.init(absolutePath: absolutePath)
            
            // TODO: Make sure the destination is a valid directory!
            
            // The name should be identical to the alias' name
            self.name = URL(string: aliasPath)!.lastPathComponent
            
            // Update the alias' path
            self.aliasPath = aliasPath
        }
        
        private func detectSiteProperties() {
            // TODO: Determine additional information, like Composer status and PHP version?
        }
    }

    struct Configuration: Decodable {
        let tld: String
        let paths: [String]
        let loopback: String
    }
    
}
