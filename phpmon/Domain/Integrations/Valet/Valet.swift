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
    
    /// The version of Valet that was detected.
    var version: String
    
    /// The Valet configuration file.
    var config: Valet.Configuration
    
    /// A cached list of sites that were detected after analyzing the paths set up for Valet.
    var sites: [Site] = []
    
    init() {
        version = VersionExtractor.from(Actions.valet("--version"))
            ?? "UNKNOWN"
        
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/valet/config.json")
        
        config = try! JSONDecoder().decode(
            Valet.Configuration.self,
            from: try! String(contentsOf: file, encoding: .utf8).data(using: .utf8)!
        )
        
        self.sites = []
    }
    
    public func startPreloadingSites() {
        let maximumPreload = 10
        let foundSites = self.countPaths()
        if foundSites <= maximumPreload {
            // Preload the sites and their drivers
            print("Fewer than or \(maximumPreload) sites found, preloading list of sites...")
            self.reloadSites()
        } else {
            print("\(foundSites) sites found, exceeds \(maximumPreload) for preload at launch!")
        }
    }
    
    public func reloadSites() {
        resolvePaths(tld: config.tld)
    }
    
    public func validateVersion() -> Void {
        if version == "UNKNOWN" {
            return print("The Valet version could not be extracted... that does not bode well.")
        }
        
        if version.versionCompare(Constants.MinimumRecommendedValetVersion) == .orderedAscending {
            let version = version
            print("Valet version \(version) is too old! (recommended: \(Constants.MinimumRecommendedValetVersion))")
            DispatchQueue.main.async {
                Alert.notify(message: "alert.min_valet_version.title".localized, info: "alert.min_valet_version.info".localized(version, Constants.MinimumRecommendedValetVersion))
            }
        } else {
            print("Valet version \(version) is recent enough, OK (recommended: \(Constants.MinimumRecommendedValetVersion))")
        }
    }
    
    private func countPaths() -> Int {
        var count = 0
        for path in config.paths {
            let entries = try! FileManager.default.contentsOfDirectory(atPath: path)
            for entry in entries {
                if resolveSite(entry, forPath: path) {
                    count += 1
                }
            }
        }
        return count
    }
    
    private func resolvePaths(tld: String) {
        sites = []
        
        for path in config.paths {
            let entries = try! FileManager.default.contentsOfDirectory(atPath: path)
            for entry in entries {
                resolvePath(entry, forPath: path, tld: tld)
            }
        }
    }
    
    private func resolveSite(_ entry: String, forPath path: String) -> Bool {
        let siteDir = path + "/" + entry

        let attrs = try! FileManager.default.attributesOfItem(atPath: siteDir)
        
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        if type == FileAttributeType.typeSymbolicLink || type == FileAttributeType.typeDirectory {
            return true
        }
        
        return false
    }
    
    private func resolvePath(_ entry: String, forPath path: String, tld: String) {
        let siteDir = path + "/" + entry
        
        // See if the file is a symlink, if so, resolve it
        let attrs = try! FileManager.default.attributesOfItem(atPath: siteDir)
        
        // We can also determine whether the thing at the path is a directory, too
        let type = attrs[FileAttributeKey.type] as! FileAttributeType
        
        // We should also check that we can interpret the path correctly
        if URL(fileURLWithPath: siteDir).lastPathComponent == "" {
            print("Warning: could not parse the site: \(siteDir), skipping!")
            return
        }
        
        if type == FileAttributeType.typeSymbolicLink {
            sites.append(Site(aliasPath: siteDir, tld: tld))
        } else if type == FileAttributeType.typeDirectory {
            sites.append(Site(absolutePath: siteDir, tld: tld))
        }
    }
    
    // MARK: - Structs
    
    class Site {
        /// Name of the site. Does not include the TLD.
        var name: String!
        
        /// The absolute path to the directory that is served.
        var absolutePath: String!
        
        /// Location of the alias. If set, this is a linked domain.
        var aliasPath: String?
        
        /// Whether the site has been secured.
        var secured: Bool!
        
        /// What driver is currently in use. If not detected, defaults to nil.
        var driver: String? = nil
        
        init() {}
        
        convenience init(absolutePath: String, tld: String) {
            self.init()
            self.absolutePath = absolutePath
            self.name = URL(fileURLWithPath: absolutePath).lastPathComponent
            self.aliasPath = nil
            determineSecured(tld)
            determineDriver()
        }
        
        convenience init(aliasPath: String, tld: String) {
            self.init()
            self.absolutePath = try! FileManager.default.destinationOfSymbolicLink(atPath: aliasPath)
            self.name = URL(fileURLWithPath: aliasPath).lastPathComponent
            self.aliasPath = aliasPath
            determineSecured(tld)
            determineDriver()
        }
        
        public func determineSecured(_ tld: String) {
            let name = self.name!.replacingOccurrences(of: " ", with: "\\ ")
            secured = Shell.fileExists("~/.config/valet/Certificates/\(name).\(tld).key")
        }
        
        public func determineDriver() {
            let driver = Shell.pipe("cd \"\(absolutePath!)\" && valet which", requiresPath: true)
            if driver.contains("This site is served by") {
                self.driver = driver
                    // TODO: Use a regular expression to retrieve the driver instead?
                    .replacingOccurrences(of: "This site is served by [", with: "")
                    .replacingOccurrences(of: "ValetDriver].\n", with: "")
            } else {
                self.driver = nil
            }
        }
    }

    struct Configuration: Decodable {
        /// Top level domain suffix. Usually "test" but can be set to something else.
        /// - Important: Does not include the actual dot. ("test", not ".test"!)
        let tld: String
        
        /// The paths that need to be checked.
        let paths: [String]
        
        /// The loopback address.
        let loopback: String
        
        /// The default site that is served if the domain is not found. Optional.
        let defaultSite: String?
        
        private enum CodingKeys: String, CodingKey {
            case tld, paths, loopback, defaultSite = "default"
        }
    }
    
}
