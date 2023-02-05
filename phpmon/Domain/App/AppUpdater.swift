//
//  AppUpdater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class AppUpdater {

    public func checkForUpdates(background: Bool) async {
        if background && !Preferences.isEnabled(.automaticBackgroundUpdateCheck) {
            Log.info("Skipping automatic update check due to user preference.")
            return
        }

        Log.info("The app will search for updates...")

        let caskUrl = App.version.contains("-dev")
            ? Constants.Urls.DevBuildCaskFile
            : Constants.Urls.StableBuildCaskFile

        guard let caskFile = await CaskFile.from(url: caskUrl) else {
            Log.err("The contents of the CaskFile at '\(caskUrl.absoluteString)' could not be retrieved.")

            if !background {
                return presentCouldNotRetrieveUpdate()
            } else {
                return
            }
        }

        self.caskFile = caskFile

        if newerVersionExists() {
            presentNewerVersionAvailableAlert()
        } else {
            if !background {
                presentNoNewerVersionAvailableAlert()
            }
        }
    }

    var caskFile: CaskFile!

    public func newerVersionExists() -> Bool {
        let currentVersion = AppVersion.fromCurrentVersion()

        guard let onlineVersion = AppVersion.from(caskFile.version) else {
            Log.err("The version string from the CaskFile could not be read.")
            return false
        }

        Log.info("You are running \(currentVersion.computerReadable). The latest version is: \(onlineVersion.computerReadable).")

        // Do the comparison w/ current version
        return true
    }

    public func presentNewerVersionAvailableAlert() {
        print("A newer version is available")
    }

    public func presentNoNewerVersionAvailableAlert() {
        print("No newer version is available")
    }

    public func presentCouldNotRetrieveUpdate() {
        print("Could not retrieve update")
    }

    private func prepareForDownload() {

    }

    public static func checkIfUpgradeWasPerformed() {
        if FileSystem.fileExists("~/.config/phpmon/updater/upgrade.success") {
            // Send a notification about the update
            Task { @MainActor in
                LocalNotification.send(
                    title: "notification.phpmon_updated.title".localized,
                    subtitle: "notification.phpmon_updated.desc".localized(App.shortVersion),
                    preference: nil
                )
                try! FileSystem.remove("~/.config/phpmon/updater/upgrade.success")
            }
        }
    }
}
