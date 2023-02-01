//
//  AppDelegate.swift
//  PHP Monitor Updater
//
//  Created by Nico Verbruggen on 01/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var updaterDirectory: String = ""

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        print("PHP MONITOR SELF-UPDATER by Nico Verbruggen")

        self.updaterDirectory = "~/.config/phpmon/updater"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        print("Updater directory set to: \(self.updaterDirectory)")

        // Download the latest file
        let zipPath = self.download(
            // zipUrl: "https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon.zip",
            // sha256: "654dd1df64ae32b1e3b9ebed7f6d89d04ed374b0b4d6732704e6df190169214f"
            
            zipUrl: "https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon-dev.zip",
            sha256: "1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a"
        )

        // Terminating all instances of PHP Monitor first
        terminatePhpMon()

        // We made it!
        install(zipPath: zipPath)

        // Restart PHP Monitor, this will also close the updater
        restartPhpMon(dev: zipPath.contains("dev"))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit(1)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    private func download(zipUrl: String, sha256: String) -> String {
        // Remove all zips
        system_quiet("rm -rf \(updaterDirectory)/*.zip")

        // Download the file (and follow redirects + no output on failure)
        system_quiet("cd \(updaterDirectory) && curl \(zipUrl) -fLO")

        // Identify the downloaded file
        let filename = system("cd \(updaterDirectory) && ls | grep .zip")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if filename.isEmpty {
            print("The update has not been downloaded. Sadly, that means that PHP Monitor cannot not updated!")

            showAlert(title: "The update was not downloaded.",
                      description: "PHP Monitor will not be updated, but we will restart the app for you. You may not be connected to the internet or the server may be encountering issues. Please try again later!")

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

        // Calculate the checksum for the downloaded file
        let checksum = system("openssl dgst -sha256 \(updaterDirectory)/\(filename) | awk '{print $NF}'")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("""
        Comparing checksums...
        Expected SHA256: \(sha256)
        Actual SHA256: \(checksum)
        """)

        // Make sure the checksum matches before we do anything with the file
        if checksum != sha256 {
            print("The checksums failed to match. Cancelling!")
            showAlert(
                title: "The downloaded update failed checksum validation",
                description: "Please try again! If this issue persists, there may be an issue with the server and I do not recommend upgrading."
            )
            exit(0)
        }

        return "\(updaterDirectory)/\(filename)"
    }

    private func install(zipPath: String) {
        system_quiet("rm -rf \(updaterDirectory)/output")
        system_quiet("mkdir -p \(updaterDirectory)/output")

        var isDirectory: ObjCBool = true
        if !FileManager.default.fileExists(atPath: "\(updaterDirectory)/output", isDirectory: &isDirectory) {
            showAlert(
                title: "The updater directory is missing",
                description: "The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable."
            )
            exit(0)
        }

        system_quiet("unzip \(zipPath) -d \(updaterDirectory)/output")

        let expectedAppName = zipPath.contains("dev")
            ? "PHP Monitor DEV.app"
            : "PHP Monitor.app"

        print("Removing \(expectedAppName) before replacing...")

        system_quiet("rm -rf \"/Applications/\(expectedAppName)\"")
        system_quiet("mv \"\(updaterDirectory)/output/\(expectedAppName)\" \"/Applications/\(expectedAppName)\"")
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
