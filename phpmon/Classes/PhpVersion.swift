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
        let version = Shell.shared
            // Get the version directly from PHP
            .pipe("php -r 'print phpversion();'")
        
        // That's the long version
        self.long = version
        
        // Next up, let's strip away the minor version number
        let segments = long.components(separatedBy: ".")
        // Get the first two elements
        self.short = segments[0...1].joined(separator: ".")
    }
}
