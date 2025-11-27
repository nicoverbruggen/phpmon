//
//  AppUpdater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import NVAlert

/**
 The potential different outcomes of a check for updates.
 */
enum UpdateCheckResult {
    case success
    case networkError
    case parseError
}

/**
 Instead of using `UpdateCheck` which is a more simplified update checking process
 included in `NVAppUpdater`, we have a slightly more complex setup here.
 */
class AppUpdater {
    var caskFile: CaskFile!
    var latestVersionOnline: AppVersion!
    var interactive: Bool = false

    public func checkForUpdates(userInitiated: Bool) async -> UpdateCheckResult {
        self.interactive = userInitiated

        Log.info("The app will search for updates...")

        let caskUrl = Constants.Urls.UpdateCheckEndpoint

        guard let caskFile = try? await CaskFile.fromUrl(App.shared.container, caskUrl) else {
            await presentCouldNotRetrieveUpdateIfInteractive()
            return .networkError
        }

        self.caskFile = caskFile

        let currentVersion = AppVersion.fromCurrentVersion()

        guard let onlineVersion = AppVersion.from(caskFile.version) else {
            Log.err("The version string from the CaskFile could not be read.")
            await presentCouldNotRetrieveUpdateIfInteractive()
            return .parseError
        }

        latestVersionOnline = onlineVersion
        Log.info("The latest version read from '\(caskUrl.lastPathComponent)' is: v\(onlineVersion.computerReadable).")

        Task { // Present this concurrently w/ returning the .success value
            if latestVersionOnline > currentVersion {
                await presentNewerVersionAvailableAlert()
            } else if interactive {
                await presentNoNewerVersionAvailableAlert()
            }
        }

        return .success
    }

    @MainActor private func presentCouldNotRetrieveUpdateIfInteractive() {
        if interactive {
            return presentCouldNotRetrieveUpdate()
        }
    }

    // MARK: - Alerts

    @MainActor public func presentNewerVersionAvailableAlert() {
        NVAlert().withInformation(
            title: "updater.alerts.newer_version_available.title"
                .localized(latestVersionOnline.humanReadable),
            subtitle: "updater.alerts.newer_version_available.subtitle"
                .localized,
            description: BrewDiagnostics.shared.customCaskInstalled
            ? "updater.installation_source.brew".localized("brew upgrade phpmon")
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
                NSWorkspace.shared.open({
                    if App.identifier.contains(".eap") {
                        return Constants.Urls.EarlyAccessChangelog
                    } else {
                        let urlSegments = self.caskFile.url.split(separator: "/")
                        let tag = urlSegments[urlSegments.count - 2] // ../download/{tag}/{file.zip}
                        return Constants.Urls.GitHubReleases.appendingPathComponent("/tag/\(tag)")
                    }
                }())
            }
        )
        .withTertiary(text: "updater.alerts.buttons.dismiss".localized, action: { vc in
            vc.close(with: .OK)
        })
        .show(urgency: interactive ? .bringToFront : .urgentRequestAttention)
    }

    @MainActor public func presentNoNewerVersionAvailableAlert() {
        NVAlert().withInformation(
            title: "updater.alerts.is_latest_version.title".localized,
            subtitle: "updater.alerts.is_latest_version.subtitle".localized(App.shortVersion),
            description: ""
        )
        .withPrimary(text: "generic.ok".localized)
        .show(urgency: interactive ? .bringToFront : .none)
    }

    @MainActor public func presentCouldNotRetrieveUpdate() {
        NVAlert().withInformation(
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
        .show(urgency: interactive ? .bringToFront : .normalRequestAttention)
    }

    // MARK: - Preparing for Self-Updater

    private func prepareForDownload() {
        let updater = Bundle.main.resourceURL!.path + "/PHP Monitor Self-Updater.app"

        system_quiet("mkdir -p ~/.config/phpmon/updater 2> /dev/null")

        let updaterDirectory = "~/.config/phpmon/updater"
            .replacing("~", with: NSHomeDirectory())

        system_quiet("cp -R \"\(updater)\" \"\(updaterDirectory)/PHP Monitor Self-Updater.app\"")

        try! App.shared.container.filesystem.writeAtomicallyToFile(
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
        let path = App.shared.container.paths.caskroomPath

        if App.shared.container.filesystem.directoryExists(path) {
            Log.info("Removing the Caskroom directory for PHP Monitor...")
            do {
                try App.shared.container.filesystem.remove(path)
                Log.info("Removed the Caskroom directory at `\(path)`.")
            } catch {
                Log.err("Automatically removing the Caskroom directory at `\(path)` failed.")
            }
        }
    }

    // MARK: - Checking if Self-Updater Worked

    public static func checkIfUpdateWasPerformed() {
        // Cleanup the upgrade.success file
        if App.shared.container.filesystem.fileExists("~/.config/phpmon/updater/upgrade.success") {
            Task { @MainActor in
                if App.identifier.contains(".phpmon.eap") {
                    LocalNotification.send(
                        title: "notification.phpmon_updated.title".localized,
                        subtitle: "notification.phpmon_updated_dev.desc".localized(App.shortVersion, App.bundleVersion),
                        preference: nil
                    )
                } else {
                    LocalNotification.send(
                        title: "notification.phpmon_updated.title".localized,
                        subtitle: "notification.phpmon_updated.desc".localized(App.shortVersion),
                        preference: nil
                    )
                }
            }

            Log.info("The `upgrade.success` file was found! An update was installed. Cleaning up...")
            try? App.shared.container.filesystem.remove("~/.config/phpmon/updater/upgrade.success")
        }

        // Cleanup the previous updater
        if App.shared.container.filesystem.anyExists("~/.config/phpmon/updater/PHP Monitor Self-Updater.app") {
            Log.info("A remnant of the self-updater must still be removed...")
            try? App.shared.container.filesystem.remove("~/.config/phpmon/updater/PHP Monitor Self-Updater.app")
        }
    }
}
