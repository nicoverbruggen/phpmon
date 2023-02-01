//
//  AppDelegate.swift
//  PHP Monitor Updater
//
//  Created by Nico Verbruggen on 01/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("PHP MONITOR UPDATER by Nico Verbruggen")
        print("Checking if contained within PHP Monitor.app...")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit(1)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
