//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import PMCommon

class PhpInstallation {
    
    var longVersion: String
    
    /**
     In order to determine details about a PHP installation, we’ll simply run `php-config --version`
     in the relevant directory.
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
    }
    
}
