//
//  Xdebug.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class Xdebug {

    public static var enabled: Bool {
        return PhpEnvironments.shared.getConfigFile(forKey: "xdebug.mode") != nil
    }

    public static var activeModes: [String] {
        guard let file = PhpEnvironments.shared.getConfigFile(forKey: "xdebug.mode") else {
            return []
        }

        guard let value = file.get(for: "xdebug.mode") else {
            return []
        }

        return value.components(separatedBy: ",").filter { self.modes.contains($0) }
    }

    public static func asMenuItems() -> [NSMenuItem] {
        var items: [NSMenuItem] = []

        let activeModes = Self.activeModes

        for mode in Self.modes {
            let item = XdebugMenuItem(
                title: mode,
                action: #selector(MainMenu.toggleXdebugMode(sender:)),
                keyEquivalent: ""
            )

            item.state = activeModes.contains(mode) ? .on : .off
            item.mode = mode
            items.append(item)
        }

        return items
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
