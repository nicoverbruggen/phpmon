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
        return PhpEnv.shared.getConfigFile(forKey: "xdebug.mode") != nil
    }

    public static var activeModes: [String] {
        guard let file = PhpEnv.shared.getConfigFile(forKey: "xdebug.mode") else {
            return []
        }

        guard let value = file.get(for: "xdebug.mode") else {
            return []
        }

        return value.components(separatedBy: ",").filter { self.modes.contains($0) }
    }

    public static var modes: [String] {
        return [
            "develop",
            "coverage",
            "debug",
            "gcstats",
            "profile",
            "trace"
        ]
    }

}
