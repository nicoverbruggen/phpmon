//
//  PhpInstall.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstall {

    var version: Version = Version()
    var xdebug: Xdebug = Xdebug()
    
    // MARK: - Computed
    
    var formula: String {
        return (self.version.short == App.shared.brewPhpVersion) ? "php" : "php@\(self.version.short)"
    }
    
    // MARK: - Initializer

    init() {
        let version = Command.execute(path: Paths.php(), arguments: ["-r", "print phpversion();"])
        
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
        
        // Determine the Xdebug status
        self.xdebug = Xdebug(
            found: Actions.didFindXdebug(self.version.short),
            enabled: Actions.didEnableXdebug(self.version.short)
        )
        
        self.version.error = false
    }
    
    // MARK: - Structs
    
    struct Version {
        var short = "???"
        var long = "???"
        var error = false
    }
    
    struct Xdebug {
        var found: Bool = false
        var enabled: Bool = false
    }
}
