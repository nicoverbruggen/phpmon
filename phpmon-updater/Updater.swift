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
    var manifestPath: String = ""
    var manifest: ReleaseManifest! = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Task { await self.installUpdate() }
    }

    func installUpdate() async {
        print("PHP MONITOR SELF-UPDATER by Nico Verbruggen")
        print("===========================================")

        self.updaterDirectory = "~/.config/phpmon/updater"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        print("Updater directory set to: \(self.updaterDirectory)")

        self.manifestPath = "\(updaterDirectory)/update.json"

        // Fetch the manifest on the local filesystem
        let manifest = await parseManifest()!

        // Download the latest file
        let zipPath = await download(manifest)

        // Terminate all instances of PHP Monitor first
        await LaunchControl.terminateApplications(bundleIds: [
            "com.nicoverbruggen.phpmon.dev",
            "com.nicoverbruggen.phpmon"
        ])

        // Install the app based on the zip
        let appPath = await extractAndInstall(zipPath: zipPath)

        // Restart PHP Monitor, this will also close the updater
        _ = await LaunchControl.startApplication(at: appPath)

        exit(1)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exit(1)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    private func parseManifest() async -> ReleaseManifest? {
        // Read out the correct information from the manifest JSON
        print("Checking manifest file at \(manifestPath)...")

        do {
            let manifestText = try String(contentsOfFile: manifestPath)
            manifest = try JSONDecoder().decode(ReleaseManifest.self, from: manifestText.data(using: .utf8)!)
            return manifest
        } catch {
            print("Parsing the manifest failed (or the manifest file doesn't exist)!")
            await Alert.show(description: "The manifest file for a potential update was not found. Please try searching for updates again in PHP Monitor.")
        }

        return nil
    }

    private func download(_ manifest: ReleaseManifest) async -> String {
        // Remove all zips
        system_quiet("rm -rf \(updaterDirectory)/*.zip")

        // Download the file (and follow redirects + no output on failure)
        system_quiet("cd \(updaterDirectory) && curl \(manifest.url) -fLO")

        // Identify the downloaded file
        let filename = system("cd \(updaterDirectory) && ls | grep .zip")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Ensure the zip exists
        if filename.isEmpty {
            print("The update has not been downloaded. Sadly, that means that PHP Monitor cannot not updated!")
            await Alert.show(description: "PHP Monitor has not been updated. The update was not downloaded, or the file could not be written to disk. Please try again.")
        }

        // Calculate the checksum for the downloaded file
        let checksum = system("openssl dgst -sha256 \(updaterDirectory)/\(filename) | awk '{print $NF}'")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Compare the checksums
        print("""
        Comparing checksums...
        Expected SHA256: \(manifest.sha256)
        Actual SHA256: \(checksum)
        """)

        // Make sure the checksum matches before we do anything with the file
        if checksum != manifest.sha256 {
            print("The checksums failed to match. Cancelling!")
            await Alert.show(description: "The downloaded update failed checksum validation. Please try again. If this issue persists, there may be an issue with the server and I do not recommend upgrading.")
        }

        // Return the path to the zip
        return "\(updaterDirectory)/\(filename)"
    }

    private func extractAndInstall(zipPath: String) async -> String {
        // Remove the directory that will contain the extracted update
        system_quiet("rm -rf \(updaterDirectory)/extracted")

        // Recreate the directory where we will unzip the .app file
        system_quiet("mkdir -p \(updaterDirectory)/extracted")

        // Make sure the updater directory exists
        var isDirectory: ObjCBool = true
        if !FileManager.default.fileExists(atPath: "\(updaterDirectory)/extracted", isDirectory: &isDirectory) {
            await Alert.show(description: "The updater directory is missing. The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable.")
        }

        // Unzip the file
        system_quiet("unzip \(zipPath) -d \(updaterDirectory)/extracted")

        // Find the .app file
        let app = system("ls \(updaterDirectory)/extracted | grep .app")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("Finished extracting: \(updaterDirectory)/extracted/\(app)")

        // Make sure the file was extracted
        if app.isEmpty {
            await Alert.show(description: "The downloaded file could not be extracted. The automatic updater will quit. Make sure that ` ~/.config/phpmon/updater` is writeable.")
        }

        // Remove the original app
        print("Removing \(app) before replacing...")
        system_quiet("rm -rf \"/Applications/\(app)\"")

        // Move the new app in place
        system_quiet("mv \"\(updaterDirectory)/extracted/\(app)\" \"/Applications/\(app)\"")

        // Remove the zip
        system_quiet("rm \(zipPath)")

        // Remove the manifest
        system_quiet("rm \(manifestPath)")

        // Write a file that is only written when we upgraded successfully
        system_quiet("touch \(updaterDirectory)/upgrade.success")

        // Return the new location of the app
        return "/Applications/\(app)"
    }
}
