//
//  Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class Valet {
    
    static let shared = Valet()
    
    var version: String
    var config: Valet.Configuration
    
    var sites: [Site] = []
    
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
        
        resolvePaths(tld: self.config.tld)
    }
    
    private func resolvePaths(tld: String) {
        self.sites = []
        
        for path in self.config.paths {
            let entries = try! FileManager.default.contentsOfDirectory(atPath: path)
            for entry in entries {
                self.resolvePath(entry, forPath: path, tld: tld)
            }
        }
    }
    
    private func resolvePath(_ entry: String, forPath path: String, tld: String) {
        let siteDir = path + "/" + entry
        
        // See if the file is a symlink, if so, resolve it
        let attrs = try! FileManager.default.attributesOfItem(atPath: siteDir)
        
        // We can also determine whether the thing at the path is a directory, too
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        if type == FileAttributeType.typeSymbolicLink {
            self.sites.append(Site(aliasPath: siteDir, tld: tld))
        } else if type == FileAttributeType.typeDirectory {
            self.sites.append(Site(absolutePath: siteDir, tld: tld))
        }
    }
    
    // MARK: - Structs
    
    class Site {
        var name: String!
        
        var absolutePath: String!
        var aliasPath: String?
        
        var secured: Bool!
        var driver: String = "???"
        
        init() {}
        
        convenience init(absolutePath: String, tld: String) {
            self.init()
            self.absolutePath = absolutePath
            self.name = URL(string: absolutePath)!.lastPathComponent
            self.aliasPath = nil
            determineSecured(tld)
            determineDriver()
        }
        
        convenience init(aliasPath: String, tld: String) {
            self.init()
            self.absolutePath = try! FileManager.default.destinationOfSymbolicLink(atPath: aliasPath)
            self.name = URL(string: aliasPath)!.lastPathComponent
            self.aliasPath = aliasPath
            determineSecured(tld)
            determineDriver()
        }
        
        public func determineSecured(_ tld: String) {
            self.secured = Shell.fileExists("~/.config/valet/Certificates/\(self.name!).\(tld).key")
        }
        
        public func determineDriver() {
            let driver = Shell.pipe("cd \(absolutePath!) && valet which", requiresPath: true)
            if driver.contains("This site is served by") {
                self.driver = driver
                    // TODO: Use a regular expression to retrieve the driver instead?
                    .replacingOccurrences(of: "This site is served by [", with: "")
                    .replacingOccurrences(of: "ValetDriver].\n", with: "")
            } else {
                self.driver = "???"
            }
        }
    }

    struct Configuration: Decodable {
        let tld: String
        let paths: [String]
        let loopback: String
        let defaultSite: String?
        
        private enum CodingKeys: String, CodingKey {
            case tld, paths, loopback, defaultSite = "default"
        }
    }
    
}
