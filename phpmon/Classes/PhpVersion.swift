//
//  PhpVersionExtractor.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpVersion {
    
    var short : String = "???"
    var long : String = "???"
    
    init() {
        let version = Shell
            // Get the version directly from PHP
            .execute(command: "php -r 'print phpversion();'")
            // also remove any colors
            .replacingOccurrences(of: "\u{1b}(B\u{1b}[m", with: "")
        
        // That's the long version
        self.long = version
        
        // Next up, let's strip away the minor version number
        let segments = long.components(separatedBy: ".")
        // Get the first two elements
        self.short = segments[0...1].joined(separator: ".")
    }
}
