//
//  Updater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Updater {

    public static var enabled: Bool = {
        return Preferences.isEnabled(.automaticBackgroundUpdateCheck)
    }()

    public static func checkForUpdates(background: Bool = true) {
        // Information about the status of a potential background update
        if background {
            if !Preferences.isEnabled(.automaticBackgroundUpdateCheck) {
                Log.info("Automatic updates are disabled. No check will be performed.")
                return
            } else {
                Log.info("Automatic updates are enabled, a check will be performed.")
            }
        }

        // Actually check for updates
        let caskFile = App.version.contains("-dev")
            ? Constants.Urls.DevBuildCaskFile.absoluteString
            : Constants.Urls.StableBuildCaskFile.absoluteString

        // We'll find out what the new version is by using `curl`
        var command = "curl -s"

        if background {
            // If running as a background check, should only waste at most 2 secs of time
            command = "curl -s --max-time 2"
        }

        let versionString = Shell.pipe(
            "\(command) '\(caskFile)' | grep version"
        )

        guard let onlineVersion = VersionExtractor.from(versionString) else {
            Log.err("We couldn't check for updates!")

            // Only notify about connection issues if the request to check for updates was explicit
            if !background {
                notifyAboutConnectionIssue()
            }

            return
        }

        guard let current = VersionExtractor.from(App.shortVersion) else {
            Log.err("We couldn't parse the current version number!")
            return
        }

        switch onlineVersion.versionCompare(current) {
        case .orderedAscending:
            Log.info("You are running a newer version of PHP Monitor.")
        case .orderedDescending:
            Log.info("There is a newer version (\(onlineVersion)) available!")
            notifyAboutNewerVersion(version: onlineVersion)
        case .orderedSame:
            Log.info("The installed version \(current) matches the latest release (\(onlineVersion)).")
        }
    }

    private static func notifyAboutNewerVersion(version: String) {
        let dev = App.version.contains("-dev") ? "-dev" : ""

        DispatchQueue.main.async {
            BetterAlert().withInformation(
                title: "updater.alerts.newer_version_available.title".localized(version),
                subtitle: "updater.alerts.newer_version_available.subtitle".localized,
                description: HomebrewDiagnostics.customCaskInstalled
                    ? "updater.installation_source.brew".localized
                    : "updater.installation_source.direct".localized
            )
            .withPrimary(
                text: "updater.alerts.buttons.release_notes".localized,
                action: { vc in
                    vc.close(with: .OK)
                    NSWorkspace.shared.open(
                        Constants.Urls.GitHubReleases.appendingPathComponent("/tag/v\(version)\(dev)")
                    )
                }
            )
            .withTertiary(text: "Close", action: { vc in
                vc.close(with: .OK)
            })
            .show()
        }
    }

    private static func notifyAboutConnectionIssue() {
        DispatchQueue.main.async {
            BetterAlert().withInformation(
                title: "updater.errors.cannot_check_for_update.title".localized,
                subtitle: "updater.errors.cannot_check_for_update.subtitle".localized,
                description: "updater.errors.cannot_check_for_update.description".localized(
                    App.version
                )
            )
            .withTertiary(
                text: "updater.errors.buttons.releases_on_github".localized,
                action: { _ in
                    NSWorkspace.shared.open(Constants.Urls.GitHubReleases)
                }
            )
            .withPrimary(text: "OK")
            .show()
        }
    }

}
