//
//  AppDelegate.swift
//  PHP Monitor Updater
//
//  Created by Nico Verbruggen on 01/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Updater: NSObject, NSApplicationDelegate {

    var updaterDirectory: String = ""
    var manifest: ReleaseManifest! = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        print("PHP MONITOR SELF-UPDATER by Nico Verbruggen")

        self.updaterDirectory = "~/.config/phpmon/updater"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        let manifestPath = "\(updaterDirectory)/update.json"

        // Read out the correct information from the manifest JSON
        do {
            let manifestText = try String(contentsOfFile: manifestPath)
            manifest = try JSONDecoder().decode(ReleaseManifest.self, from: manifestText.data(using: .utf8)!)
        } catch {
            print("Parsing the manifest failed (or the manifest file doesn't exist)")
            showAlert(
                title: "Key information about the update is missing",
                description: "The self-updater only works in combination with PHP Monitor. Please try searching for updates again in PHP Monitor. The app has not been updated."
            )
            exit(0)
        }

        print("Updater directory set to: \(self.updaterDirectory)")

        // Download the latest file
        let zipPath = self.download(manifest)

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

    private func download(_ manifest: ReleaseManifest) -> String {
        // Remove all zips
        system_quiet("rm -rf \(updaterDirectory)/*.zip")

        // Download the file (and follow redirects + no output on failure)
        system_quiet("cd \(updaterDirectory) && curl \(manifest.url) -fLO")

        // Identify the downloaded file
        let filename = system("cd \(updaterDirectory) && ls | grep .zip")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if filename.isEmpty {
            print("The update has not been downloaded. Sadly, that means that PHP Monitor cannot not updated!")
            showAlert(title: "The update was not downloaded.",
                      description: "PHP Monitor has not been updated. You may not be connected to the internet or the server may be encountering issues, or the file could not be written to disk. Please try again later!")
            exit(1)
        }

        // Calculate the checksum for the downloaded file
        let checksum = system("openssl dgst -sha256 \(updaterDirectory)/\(filename) | awk '{print $NF}'")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("""
        Comparing checksums...
        Expected SHA256: \(manifest.sha256)
        Actual SHA256: \(checksum)
        """)

        // Make sure the checksum matches before we do anything with the file
        if checksum != manifest.sha256 {
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
        system_quiet("rm -rf \(updaterDirectory)/extracted")
        system_quiet("mkdir -p \(updaterDirectory)/extracted")

        var isDirectory: ObjCBool = true
        if !FileManager.default.fileExists(atPath: "\(updaterDirectory)/extracted", isDirectory: &isDirectory) {
            showAlert(
                title: "The updater directory is missing",
                description: "The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable."
            )
            exit(0)
        }

        system_quiet("unzip \(zipPath) -d \(updaterDirectory)/extracted")

        let expectedAppName = zipPath.contains("dev")
            ? "PHP Monitor DEV.app"
            : "PHP Monitor.app"

        print("Removing \(expectedAppName) before replacing...")

        system_quiet("rm -rf \"/Applications/\(expectedAppName)\"")
        system_quiet("mv \"\(updaterDirectory)/extracted/\(expectedAppName)\" \"/Applications/\(expectedAppName)\"")
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

    private func smartRestartPhpMon() {
        if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor.app") {
            restartPhpMon(dev: false)
        }
        else if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor DEV.app") {
            restartPhpMon(dev: true)
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
