//
//  BrewPhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {
    
    var longVersion: String
    var homebrewInfo: HomebrewPackage
    
    init(_ version: String) {
        let phpConfigExecutablePath = "\(Paths.optPath)/php@\(version)/bin/php-config"
        self.longVersion = version
        if Shell.fileExists(phpConfigExecutablePath) {
            self.longVersion = Command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"]
            )
        }
        
        let info = Shell.pipe("\(Paths.brew) info php@\(version) --json")
        self.homebrewInfo = try! JSONDecoder().decode(
            [HomebrewPackage].self,
            from: info.data(using: .utf8)!
        ).first!
    }
    
}
