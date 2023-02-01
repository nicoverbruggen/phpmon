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
        print("PHP MONITOR SELF-UPDATER by Nico Verbruggen")
        let path = "~/config/phpmon/updater/phpmon.zip"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        print("Checking path: \(path)")

        if !FileManager.default.fileExists(atPath: path) {
            print("The update has not been downloaded. Sadly, that means we will not update!")

            showAlert(title: "The archive containing the zip appears to be missing.",
                      description: "PHP Monitor will not be updated, but we will restart the app for you.")

            if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor.app") {
                restartPhpMon(dev: false)
            }
            else if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor DEV.app") {
                restartPhpMon(dev: true)
            }
            else {
                exit(1)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit(1)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func restartPhpMon(dev: Bool) {
        let path = dev ? "/Applications/PHP Monitor DEV.app" : "/Applications/PHP Monitor.app"
        let url = NSURL(fileURLWithPath: path, isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            print(app)
            exit(0)
        }
    }

    private func showAlert(title: String, description: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = description
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }
}
