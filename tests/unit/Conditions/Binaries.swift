//
//  Binaries.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

class Binaries {
    static func exist(paths: [String]) -> Bool {
        for path in paths where FileManager.default.fileExists(atPath: path) {
            return true
        }

        return false
    }

    static func hasLinkedPhp() -> Bool {
        return Binaries.exist(paths: [
            "/opt/homebrew/bin/php",
            "/usr/local/bin/php"
        ])
    }
}
