//
//  PhpVersionExtractor.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpVersionExtractor {
    
    var short : String = "???"
    var long : String = "???"
    
    init() {
        // Get the info about the PHP installation
        let output = Shell.execute(command: "php -v")
        // Get everything before "(cli)" (PHP X.X.X (cli) ...)
        var version = output!.components(separatedBy: " (cli)")[0]
        // Strip away the text before the version number
        version = version.components(separatedBy: "PHP ")[1]
        self.long = version
        // Next up, let's strip away the minor version number
        let segments = version.components(separatedBy: ".")
        // Get the first two elements
        self.short = segments[0...1].joined(separator: ".")
    }
}
