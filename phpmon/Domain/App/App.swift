//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

class App {

    // MARK: Static Vars

    /** The static app instance. Accessible at any time. */
    static let shared = App()

    /** Retrieve the version number from the main info dictionary, Info.plist. */
    static var version: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return "\(version) (\(build))"
    }

    /** Retrieve the version number from the main info dictionary, Info.plist, but without the build number. */
    static var shortVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return "\(version)"
    }

    static var architecture: String {
        var systeminfo = utsname()
        uname(&systeminfo)
        let machine = withUnsafeBytes(of: &systeminfo.machine) {bufPtr->String in
            let data = Data(bufPtr)
            if let lastIndex = data.lastIndex(where: {$0 != 0}) {
                return String(data: data[0...lastIndex], encoding: .isoLatin1)!
            } else {
                return String(data: data, encoding: .isoLatin1)!
            }
        }
        return machine
    }

    // MARK: Variables

    /** The list of preferences that are currently active. */
    var preferences: [PreferenceName: Bool]!

    /** The window controller of the currently active preferences window. */
    var preferencesWindowController: PrefsWC?

    /** The window controller of the currently active site list window. */
    var domainListWindowController: DomainListWC?

    /** List of detected (installed) applications that PHP Monitor can work with. */
    var detectedApplications: [Application] = []

    /** Timer that will periodically reload info about the user's PHP installation. */
    var timer: Timer?

    // MARK: - Global Hotkey

    /**
     The shortcut the user has requested.
     */
    var shortcutHotkey: HotKey? {
        didSet {
            setupGlobalHotkeyListener()
        }
    }

    // MARK: - Activation Policy

    /**
     Variable that keeps track of which windows are currently open.
     (Please note that window controllers remain open in memory once opened.)
     
     When this list is updated, the app activation policy is re-evaluated.
     The app activation policy dictates how the app runs
     (as a normal app or as a toolbar app).
     */
    var openWindows: [String] = []

    // MARK: - App Watchers

    /**
     The `PhpConfigWatcher` is responsible for watching the `.ini` files and the `.conf.d` folder.
     */
    var watcher: PhpConfigWatcher!
}
