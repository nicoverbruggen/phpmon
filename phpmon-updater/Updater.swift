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

        print("Updater directory set to: \(self.updaterDirectory)")

        let manifestPath = "\(updaterDirectory)/update.json"

        print("Checking manifest file at \(manifestPath)")

        // Read out the correct information from the manifest JSON
        do {
            let manifestText = try String(contentsOfFile: manifestPath)
            manifest = try JSONDecoder().decode(ReleaseManifest.self, from: manifestText.data(using: .utf8)!)
        } catch {
            print("Parsing the manifest failed (or the manifest file doesn't exist)")
            showAlert(
                title: "Key information about the update is missing",
                description: "The app has not been updated. The self-updater only works in combination with PHP Monitor. Please try searching for updates again in PHP Monitor."
            )
            exit(0)
        }

        // Download the latest file
        let zipPath = self.download(manifest)

        // Terminate all instances of PHP Monitor first
        terminatePhpMon()

        // Install the app based on the zip
        let appPath = extractAndInstall(zipPath: zipPath)

        // Restart PHP Monitor, this will also close the updater
        restartPhpMon(at: appPath)
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

    private func extractAndInstall(zipPath: String) -> String {
        // Remove the directory that will contain the extracted update
        system_quiet("rm -rf \(updaterDirectory)/extracted")

        // Recreate the directory where we will unzip the .app file
        system_quiet("mkdir -p \(updaterDirectory)/extracted")

        // Make sure the updater directory exists
        var isDirectory: ObjCBool = true
        if !FileManager.default.fileExists(atPath: "\(updaterDirectory)/extracted", isDirectory: &isDirectory) {
            showAlert(
                title: "The updater directory is missing",
                description: "The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable."
            )
            exit(0)
        }

        // Unzip the file
        system_quiet("unzip \(zipPath) -d \(updaterDirectory)/extracted")

        // Find the .app file
        let app = system("ls \(updaterDirectory)/extracted | grep .app")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("Finished extracting: \(updaterDirectory)/extracted/\(app)")

        // Make sure the file was extracted
        if app.isEmpty {
            showAlert(
                title: "The downloaded file could not be extracted",
                description: "The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable."
            )
            exit(0)
        }

        print("Removing \(app) before replacing...")

        system_quiet("rm -rf \"/Applications/\(app)\"")
        system_quiet("mv \"\(updaterDirectory)/extracted/\(app)\" \"/Applications/\(app)\"")

        return "/Applications/\(app)"
    }

    private func terminatePhpMon() {
        let runningApplications = NSWorkspace.shared.runningApplications

        // Look for these instances
        let ids = [
            "com.nicoverbruggen.phpmon.dev",
            "com.nicoverbruggen.phpmon"
        ]

        // Terminate all instances found
        for id in ids {
            if let phpmon = runningApplications.first(where: {
                (application) in return application.bundleIdentifier == id
            }) {
                phpmon.terminate()
            }
        }
    }

    private func smartRestartPhpMon() {
        if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor.app") {
            restartPhpMon(at: "/Applications/PHP Monitor.app")
        }
        else if FileManager.default.fileExists(atPath: "/Applications/PHP Monitor DEV.app") {
            restartPhpMon(at: "/Applications/PHP Monitor DEV.app")
        }
    }

    private func restartPhpMon(at path: String) {
        let url = NSURL(fileURLWithPath: path, isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { phpmon, error in
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
