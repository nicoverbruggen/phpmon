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

        // Figure out where the updater would like to find the
        let path = "~/.config/phpmon/updater/phpmon.zip"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        // Terminating all instances of PHP Monitor first
        terminatePhpMon()

        // Checking if the updated file exists
        print("Checking path: \(path)")

        // If the file does not exist, exit gracefully
        if !FileManager.default.fileExists(atPath: path) {
            print("The update has not been downloaded. Sadly, that means that PHP Monitor cannot not updated!")

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

        // We made it!
        install(zipPath: path)

        // Restart PHP Monitor, this will also close the updater
        restartPhpMon(dev: false)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit(1)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func install(zipPath: String) {
        _ = system("rm -rf ~/.config/phpmon/updater/output")
        _ = system("mkdir -p ~/.config/phpmon/updater/output")
        _ = system("unzip \(zipPath) -d ~/.config/phpmon/updater/output")
        _ = system("rm -rf \"/Applications/PHP Monitor.app\"")
        let command = "mv \"~/.config/phpmon/updater/output/PHP Monitor.app\" \"/Applications/PHP Monitor.app\""
            .replacingOccurrences(of: "~", with: NSHomeDirectory())
        _ = system(command)
    }

    private func terminatePhpMon() {
        let runningApplications = NSWorkspace.shared.runningApplications

        let ids = [
            "com.nicoverbruggen.phpmon.dev",
            "com.nicoverbruggen.phpmon"
        ]

        for id in ids {
            if let phpmon = runningApplications
                .first(where: { (application) in return application.bundleIdentifier == id }) {
                phpmon.terminate()
            }
        }
    }

    private func restartPhpMon(dev: Bool) {
        let path = dev ? "/Applications/PHP Monitor DEV.app" : "/Applications/PHP Monitor.app"
        let url = NSURL(fileURLWithPath: path, isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { phpmon, error in
            // Once we've opened PHP Monitor again... quit the updater
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
