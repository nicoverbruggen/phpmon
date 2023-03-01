//
//  AppUpdater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class AppUpdater {
    var caskFile: CaskFile!
    var latestVersionOnline: AppVersion!
    var interactive: Bool = false

    public func checkForUpdates(interactive: Bool) async {
        self.interactive = interactive

        if interactive && !Preferences.isEnabled(.automaticBackgroundUpdateCheck) {
            Log.info("Skipping automatic update check due to user preference.")
            return
        }

        Log.info("The app will search for updates...")

        let caskUrl = App.identifier.contains(".dev")
            ? Constants.Urls.DevBuildCaskFile
            : Constants.Urls.StableBuildCaskFile

        guard let caskFile = await CaskFile.from(url: caskUrl) else {
            Log.err("The contents of the CaskFile at '\(caskUrl.absoluteString)' could not be retrieved.")
            return presentCouldNotRetrieveUpdateIfInteractive()
        }

        self.caskFile = caskFile

        let currentVersion = AppVersion.fromCurrentVersion()

        guard let onlineVersion = AppVersion.from(caskFile.version) else {
            Log.err("The version string from the CaskFile could not be read.")
            return presentCouldNotRetrieveUpdateIfInteractive()
        }

        latestVersionOnline = onlineVersion
        Log.info("The latest version read from '\(caskUrl.lastPathComponent)' is: v\(onlineVersion.computerReadable).")

        if latestVersionOnline > currentVersion {
            presentNewerVersionAvailableAlert()
        } else if interactive {
            presentNoNewerVersionAvailableAlert()
        }
    }

    private func presentCouldNotRetrieveUpdateIfInteractive() {
        if interactive {
            return presentCouldNotRetrieveUpdate()
        } else {
            return
        }
    }

    // MARK: - Alerts

    public func presentNewerVersionAvailableAlert() {
        let command = App.identifier.contains(".dev")
            ? "brew upgrade phpmon-dev"
            : "brew upgrade phpmon"

        Task { @MainActor in
            BetterAlert().withInformation(
                title: "updater.alerts.newer_version_available.title"
                    .localized(latestVersionOnline.humanReadable),
                subtitle: "updater.alerts.newer_version_available.subtitle"
                    .localized,
                description: HomebrewDiagnostics.customCaskInstalled
                ? "updater.installation_source.brew".localized(command)
                : "updater.installation_source.direct".localized
            )
            .withPrimary(
                text: "updater.alerts.buttons.install".localized,
                action: { vc in
                    self.cleanupCaskroom()
                    self.prepareForDownload()
                    vc.close(with: .OK)
                }
            )
            .withSecondary(
                text: "updater.alerts.buttons.release_notes".localized,
                action: { _ in
                    let urlSegments = self.caskFile.url.split(separator: "/")
                    let tag = urlSegments[urlSegments.count - 2] // ../download/{tag}/{file.zip}
                    NSWorkspace.shared.open(
                        Constants.Urls.GitHubReleases.appendingPathComponent("/tag/\(tag)")
                    )
                }
            )
            .withTertiary(text: "updater.alerts.buttons.dismiss".localized, action: { vc in
                vc.close(with: .OK)
            })
            .show()
        }
    }

    public func presentNoNewerVersionAvailableAlert() {
        Task { @MainActor in
            BetterAlert().withInformation(
                title: "updater.alerts.is_latest_version.title".localized,
                subtitle: "updater.alerts.is_latest_version.subtitle".localized(App.shortVersion),
                description: ""
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
        }
    }

    public func presentCouldNotRetrieveUpdate() {
        Task { @MainActor in
            BetterAlert().withInformation(
                title: "updater.alerts.cannot_check_for_update.title".localized,
                subtitle: "updater.alerts.cannot_check_for_update.subtitle".localized,
                description: "updater.alerts.cannot_check_for_update.description".localized(
                    App.version
                )
            )
            .withTertiary(
                text: "updater.alerts.buttons.releases_on_github".localized,
                action: { _ in
                    NSWorkspace.shared.open(Constants.Urls.GitHubReleases)
                }
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
        }
    }

    // MARK: - Preparing for Self-Updater

    private func prepareForDownload() {
        let updater = Bundle.main.resourceURL!.path + "/PHP Monitor Self-Updater.app"

        system_quiet("mkdir -p ~/.config/phpmon/updater 2> /dev/null")

        let updaterDirectory = "~/.config/phpmon/updater"
            .replacingOccurrences(of: "~", with: NSHomeDirectory())

        system_quiet("cp -R \"\(updater)\" \"\(updaterDirectory)/PHP Monitor Self-Updater.app\"")

        try! FileSystem.writeAtomicallyToFile(
            "\(updaterDirectory)/update.json",
            content: "{ \"url\": \"\(caskFile.url)\", \"sha256\": \"\(caskFile.sha256)\" }"
        )

        let updaterUrl = NSURL(fileURLWithPath: updater, isDirectory: true) as URL
        let configuration = NSWorkspace.OpenConfiguration()

        NSWorkspace.shared.openApplication(at: updaterUrl, configuration: configuration) { _, _ in
            Log.info("The updater has been launched successfully!")
        }
    }

    private func cleanupCaskroom() {
        let path = Paths.caskroomPath

        if FileSystem.directoryExists(path) {
            Log.info("Removing the Caskroom directory for PHP Monitor...")
            do {
                try FileSystem.remove(path)
                Log.info("Removed the Caskroom directory at `\(path)`.")
            } catch {
                Log.err("Automatically removing the Caskroom directory at `\(path)` failed.")
            }
        }
    }

    // MARK: - Checking if Self-Updater Worked

    public static func checkIfUpdateWasPerformed() {
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
