//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {
    
    var longVersion: String
    var homebrewInfo: HomebrewPackage?
    
    /**
     In order to determine details about a PHP installation, we’ll simply run `php-config --version`
     in the relevant directory, and we’ll also attempt to determine information about the Homebrew
     formula for that particular installation.
     */
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
        
        do {
            self.homebrewInfo = try JSONDecoder().decode(
                [HomebrewPackage].self,
                from: info.data(using: .utf8)!
            ).first ?? nil
        } catch {
            // TODO: Perhaps show a modal to indicate there’s an issue with Homebrew?
            print("There was an issue parsing Homebrew info for PHP \(version)")
            self.homebrewInfo = nil
        }
    }
    
}
