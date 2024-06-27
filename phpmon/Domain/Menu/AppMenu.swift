//
//  AppMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/06/2024.
//  Copyright © 2024 Nico Verbruggen. All rights reserved.
//

import Cocoa

class AppMenu {

    // MARK: - Main Menu

    static var appMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[0].submenu
    }

    static var sitesMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[1].submenu
    }

    static var editMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[2].submenu
    }

    static var windowMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[3].submenu
    }

    static var helpMenu: NSMenu? {
        return NSApplication.shared.mainMenu?.items[4].submenu
    }

    // MARK: - Submenu

    static var actionsMenu: NSMenuItem? {
        return sitesMenu?.items.last
    }

}
