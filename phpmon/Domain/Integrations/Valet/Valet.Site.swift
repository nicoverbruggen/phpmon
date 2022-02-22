//
//  Valet+Subclasses.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Valet {
    
    class Site {
        
        /// Name of the site. Does not include the TLD.
        var name: String!
        
        /// The absolute path to the directory that is served.
        var absolutePath: String!
        
        /// The absolute path to the directory that is served,
        /// replacing the user's home folder with ~.
        lazy var absolutePathRelative: String = {
            return self.absolutePath
                .replacingOccurrences(of: "/Users/\(Paths.whoami)", with: "~")
        }()
        
        /// Location of the alias. If set, this is a linked domain.
        var aliasPath: String?
        
        /// Whether the site has been secured.
        var secured: Bool!
        
        /// What driver is currently in use. If not detected, defaults to nil.
        var driver: String? = nil
        
        /// Whether the driver was determined by checking the Composer file.
        var driverDeterminedByComposer: Bool = false
        
        /// A list of notable Composer dependencies.
        var notableComposerDependencies: [String: String] = [:]
        
        /// The PHP version as discovered in `composer.json` or in .valetphprc.
        var composerPhp: String = "???"
        
        /// Check whether the PHP version is valid for the currently linked version.
        var composerPhpCompatibleWithLinked: Bool = false
        
        /// How the PHP version was determined.
        var composerPhpSource: VersionSource = .unknown
        
        enum VersionSource: String {
            case unknown = "unknown"
            case require = "require"
            case platform = "platform"
            case valetphprc = "valetphprc"
        }
        
        init() {}
        
        convenience init(absolutePath: String, tld: String) {
            self.init()
            self.absolutePath = absolutePath
            self.name = URL(fileURLWithPath: absolutePath).lastPathComponent
            self.aliasPath = nil
            determineSecured(tld)
            determineComposerPhpVersion()
            determineDriver()
        }
        
        convenience init(aliasPath: String, tld: String) {
            self.init()
            self.absolutePath = try! FileManager.default.destinationOfSymbolicLink(atPath: aliasPath)
            self.name = URL(fileURLWithPath: aliasPath).lastPathComponent
            self.aliasPath = aliasPath
            determineSecured(tld)
            determineComposerPhpVersion()
            determineDriver()
        }
        
        /**
         Checks if a certificate file can be found in the `valet/Certificates` directory.
         - Note: The file is not validated, only its presence is checked.
         */
        public func determineSecured(_ tld: String) {
            secured = Filesystem.fileExists("~/.config/valet/Certificates/\(self.name!).\(tld).key")
        }
        
        /**
         Checks if `composer.json` exists in the folder, and extracts notable information:
         
         - The PHP version required (the constraint, so it could be `^8.0`, for example)
         - Where the PHP version was found (`require` or `platform` or via .valetphprc)
         - Notable PHP dependencies (determined via `PhpFrameworks.DependencyList`)
         
         The method then also checks if the determined constraint (if found) is compatible
         with the currently linked version of PHP (see `composerPhpMatchesSystem`).
         */
        public func determineComposerPhpVersion() {
            do {
                let path = "\(absolutePath!)/composer.json"
                
                if Filesystem.fileExists(path) {
                    let decoded = try JSONDecoder().decode(
                        ComposerJson.self,
                        from: String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8).data(using: .utf8)!
                    )
                    
                    (self.composerPhp, self.composerPhpSource) = decoded.getPhpVersion()
                    self.notableComposerDependencies = decoded.getNotableDependencies()
                }
            } catch {
                Log.err("Something went wrong reading the Composer JSON file.")
            }
            
            do {
                let path = "\(absolutePath!)/.valetphprc"
                
                if Filesystem.fileExists(path) {
                    let contents = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
                    if let version = VersionExtractor.from(contents) {
                        self.composerPhp = version
                        self.composerPhpSource = .valetphprc
                    }
                }
            } catch {
                Log.err("Something went wrong parsing the .valetphprc file")
            }
            
            // TODO: Check if .valetphprc exists and if it contains a valid version number
            
            if self.composerPhp == "???" {
                return
            }
            
            // Split the composer list (on "|") to evaluate multiple constraints
            // For example, for Laravel 8 projects the value is "^7.3|^8.0"
            self.composerPhpCompatibleWithLinked =
            self.composerPhp.split(separator: "|").map { string in
                return PhpVersionNumberCollection.make(from: [PhpEnv.phpInstall.version.long])
                    .matching(constraint: string.trimmingCharacters(in: .whitespacesAndNewlines))
                    .count > 0
            }.contains(true)
        }
        
        /**
         Determine the driver to be displayed in the list of sites. In v5.0, this has been changed
         to load the "framework" or "project type" instead.
         */
        public func determineDriver() {
            self.determineDriverViaComposer()
            
            if self.driver == nil {
                self.driver = PhpFrameworks.detectFallbackDependency(self.absolutePath)
            }
        }
        
        /**
         Check the dependency list and see if a particular dependency can't be found.
         We'll revert the dependency list so that Laravel and Symfony are detected last.
         
         (Some other frameworks might use Laravel, so if we found it first the detection would be incorrect:
         this would happen with Statamic, for example.)
         */
        private func determineDriverViaComposer() {
            self.driverDeterminedByComposer = true
            
            PhpFrameworks.DependencyList.reversed().forEach { (key: String, value: String) in
                if self.notableComposerDependencies.keys.contains(key) {
                    self.driver = value
                }
            }
        }
        
        @available(*, deprecated, renamed: "determineDriver")
        private func determineDriverViaValet() {
            let driver = Shell.pipe("cd '\(absolutePath!)' && valet which", requiresPath: true)
            if driver.contains("This site is served by") {
                self.driver = driver
                    .replacingOccurrences(of: "This site is served by [", with: "")
                    .replacingOccurrences(of: "ValetDriver].\n", with: "")
            } else {
                self.driver = nil
            }
        }
    }
    
}
