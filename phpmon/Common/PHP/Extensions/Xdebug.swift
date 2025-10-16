//
//  Xdebug.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import ContainerMacro

@ContainerAccess
class Xdebug {
    public var enabled: Bool {
        return phpEnvs.getConfigFile(forKey: "xdebug.mode") != nil
    }

    public var activeModes: [String] {
        guard let file = phpEnvs.getConfigFile(forKey: "xdebug.mode") else {
            return []
        }

        guard let value = file.get(for: "xdebug.mode") else {
            return []
        }

        return value.components(separatedBy: ",").filter { self.availableModes.contains($0) }
    }

    public func asMenuItems() -> [NSMenuItem] {
        var items: [NSMenuItem] = []

        for mode in availableModes {
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

    public var availableModes: [String] {
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
