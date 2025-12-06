//
//  Xdebug.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/05/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class Xdebug {

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Variables

    public var enabled: Bool {
        return container.phpEnvs.getConfigFile(forKey: "xdebug.mode") != nil
    }

    public var activeModes: [String] {
        guard let file = container.phpEnvs.getConfigFile(forKey: "xdebug.mode") else {
            return []
        }

        guard let value = file.get(for: "xdebug.mode") else {
            return []
        }

        return value.components(separatedBy: ",").filter { self.availableModes.contains($0) }
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

    // MARK: - Methods

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

}
