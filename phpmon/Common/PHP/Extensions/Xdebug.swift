//
//  Xdebug.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class Xdebug {
    
    public static var enabled: Bool {
        return !self.mode.isEmpty
    }
    
    public static var mode: String {
        return Command.execute(path: Paths.php, arguments: ["-r", "echo ini_get('xdebug.mode');"])
    }
    
    public static var modes: [String] {
        return [
            "off",
            "develop",
            "coverage",
            "debug",
            "gcstats",
            "profile",
            "trace",
        ]
    }
    
}
