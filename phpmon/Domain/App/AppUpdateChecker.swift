//
//  Updater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class AppUpdateChecker {

    public static var enabled: Bool = {
        return Preferences.isEnabled(.automaticBackgroundUpdateCheck)
    }()

    public static var isDev: Bool = {
        return App.version.contains("-dev")
    }()

    public static func retrieveVersionFromCask(
        _ initiatedFromBackground: Bool = true
    ) -> String {
        let caskFile = App.version.contains("-dev")
        ? Constants.Urls.DevBuildCaskFile.absoluteString
        : Constants.Urls.StableBuildCaskFile.absoluteString

        var command = "curl -s"

        if initiatedFromBackground {
            command = "curl -s --max-time 5"
        }

        return Shell.pipe(
            "\(command) '\(caskFile)' | grep version"
        )
    }

    public static func checkIfNewerVersionIsAvailable(
        initiatedFromBackground: Bool = true
    ) {
        if initiatedFromBackground {
            if !Preferences.isEnabled(.automaticBackgroundUpdateCheck) {
                Log.info("Automatic updates are disabled. No check will be performed.")
                return
            }

            Log.info("Automatic updates are enabled, a check will be performed.")
        }

        let versionString = retrieveVersionFromCask(initiatedFromBackground)

        guard let onlineVersion = AppVersion.from(versionString) else {
            Log.err("We couldn't check for updates!")

            // Only notify about connection issues if the request to check for updates was explicit
            if !initiatedFromBackground {
                notifyAboutConnectionIssue()
            }

            return
        }

        let currentVersion = AppVersion.fromCurrentVersion()

        handleVersionComparison(
            currentVersion,
            onlineVersion,
            initiatedFromBackground
        )
    }

    private static func handleVersionComparison(
        _ currentVersion: AppVersion,
        _ onlineVersion: AppVersion,
        _ background: Bool
    ) {
        switch onlineVersion.comparable.versionCompare(currentVersion.comparable) {
        case .orderedAscending:
            Log.info("You are running a newer version of PHP Monitor.")
            if !background { notifyVersionDoesNotNeedUpgrade() }
        case .orderedDescending:
            Log.info("There is a newer version (\(onlineVersion)) available!")
            notifyAboutNewerVersion(version: onlineVersion)
        case .orderedSame:
            Log.info("The installed version (\(currentVersion)) matches the latest release (\(onlineVersion)).")
            if !background { notifyVersionDoesNotNeedUpgrade() }
        }
    }

    private static func notifyVersionDoesNotNeedUpgrade() {
        DispatchQueue.main.async {
            BetterAlert().withInformation(
                title: "updater.alerts.is_latest_version.title".localized,
                subtitle: "updater.alerts.is_latest_version.subtitle".localized(App.shortVersion),
                description: ""
            )
            .withPrimary(text: "OK")
            .show()
        }
    }

    private static func notifyAboutNewerVersion(version: AppVersion) {
        let devSuffix = isDev ? "-dev" : ""
        let command = isDev ? "brew upgrade phpmon-dev" : "brew upgrade phpmon"

        DispatchQueue.main.async {
            BetterAlert().withInformation(
                title: "updater.alerts.newer_version_available.title".localized(version.humanReadable),
                subtitle: "updater.alerts.newer_version_available.subtitle".localized,
                description: HomebrewDiagnostics.customCaskInstalled
                    ? "updater.installation_source.brew".localized(command)
                    : "updater.installation_source.direct".localized
            )
            .withPrimary(
                text: "updater.alerts.buttons.release_notes".localized,
                action: { vc in
                    vc.close(with: .OK)
                    NSWorkspace.shared.open(
                        Constants.Urls.GitHubReleases.appendingPathComponent("/tag/v\(version.version)\(devSuffix)")
                    )
                }
            )
            .withTertiary(text: "Dismiss", action: { vc in
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
