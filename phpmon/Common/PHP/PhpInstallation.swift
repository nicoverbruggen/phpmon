//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {
    
    var longVersion: PhpVersionNumber
    
    /**
     In order to determine details about a PHP installation, we’ll simply run `php-config --version`
     in the relevant directory.
     */
    init(_ version: String) {
        
        let phpConfigExecutablePath = "\(Paths.optPath)/php@\(version)/bin/php-config"
        self.longVersion = PhpVersionNumber.make(from: version)!
        
        if Shell.fileExists(phpConfigExecutablePath) {
            let longVersionString = Command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"]
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            
            self.longVersion = PhpVersionNumber.make(
                from: String(longVersionString.split(separator: "-")[0])
            )!
        }
    }
    
}
