//
//  PhpInstall.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstall {

    var version: Version!
    var extensions: [PhpExtension]!
    
    // MARK: - Computed
    
    var formula: String {
        return (self.version.short == App.shared.brewPhpVersion) ? "php" : "php@\(self.version.short)"
    }
    
    // MARK: - Initializer

    init() {
        let version = Command.execute(path: Paths.php, arguments: ["-r", "print phpversion();"])
        
        self.version = Version()
        
        if (version == "" || version.contains("Warning")) {
            self.version.short = "💩 BROKEN"
            self.version.long = "";
            self.version.error = true
            return;
        }
        
        // That's the long version
        self.version.long = version
        
        // Next up, let's strip away the minor version number
        let segments = self.version.long.components(separatedBy: ".")
        
        // Get the first two elements
        self.version.short = segments[0...1].joined(separator: ".")
        
        // Load extension information
        let path = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(self.version.short)/php.ini")
        self.extensions = PhpExtension.load(from: path)
    }
    
    // MARK: - Structs
    
    struct Version {
        var short = "???"
        var long = "???"
        var error = false
    }
}
