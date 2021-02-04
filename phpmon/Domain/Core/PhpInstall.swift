//
//  PhpInstall.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstall {

    var version: Version
    var configuration: Configuration
    var extensions: [PhpExtension]
    
    // MARK: - Computed
    
    var formula: String {
        return (self.version.short == App.shared.brewPhpVersion) ? "php" : "php@\(self.version.short)"
    }
    
    // MARK: - Initializer

    init() {
        // Show information about the current version
        self.version = type(of: self).getVersion()
        
        // If an error occurred, exit early
        if (self.version.error) {
            self.configuration = Configuration()
            self.extensions = []
            return
        }
        
        // Load extension information
        let path = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(self.version.short)/php.ini")
        self.extensions = PhpExtension.load(from: path)
        
        // Get configuration values
        self.configuration = Configuration(
            memory_limit: type(of: self).getIniValue(key: "memory_limit"),
            upload_max_filesize: type(of: self).getIniValue(key: "upload_max_filesize"),
            post_max_size: type(of: self).getIniValue(key: "post_max_size")
        )
    }
    
    private static func getVersion() -> Version {
        var versionStruct = Version()
        let version = Command.execute(path: Paths.php, arguments: ["-r", "print phpversion();"])
        
        if (version == "" || version.contains("Warning")) {
            versionStruct.short = "💩 BROKEN"
            versionStruct.long = "";
            versionStruct.error = true
            return versionStruct;
        }
        
        // That's the long version
        versionStruct.long = version
        
        // Next up, let's strip away the minor version number
        let segments = versionStruct.long.components(separatedBy: ".")
        
        // Get the first two elements
        versionStruct.short = segments[0...1].joined(separator: ".")
        
        return versionStruct
    }
    
    private static func getIniValue(key: String) -> String {
        return Command.execute(path: Paths.php, arguments: ["-r", "echo ini_get('\(key)');"])
    }
    
    // MARK: - Structs
    
    struct Version {
        var short = "???"
        var long = "???"
        var error = false
    }
    
    struct Configuration {
        var memory_limit = "???"
        var upload_max_filesize = "???"
        var post_max_size = "???"
    }
}
