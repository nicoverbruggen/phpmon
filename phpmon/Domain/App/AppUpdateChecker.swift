//
//  Updater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class AppUpdateChecker {

    public static var latestCaskFileContents: String = ""

    public static var enabled: Bool = {
        return Preferences.isEnabled(.automaticBackgroundUpdateCheck)
    }()

    public static var isDev: Bool = {
        return App.version.contains("-dev")
    }()

    public static func retrieveVersionFromCask(
        _ initiatedFromBackground: Bool = true
    ) async -> String {
        let caskFile = App.version.contains("-dev")
        ? Constants.Urls.DevBuildCaskFile.absoluteString
        : Constants.Urls.StableBuildCaskFile.absoluteString

        var command = "curl -s"

        if initiatedFromBackground {
            command = "curl -s --max-time 5"
        }

        AppUpdateChecker.latestCaskFileContents = await Shell.pipe("\(command) '\(caskFile)'").out
        return await Shell.pipe("echo \"\(Self.latestCaskFileContents)\" | grep version").out
    }

    public static func checkIfNewerVersionIsAvailable(
        initiatedFromBackground: Bool = true
    ) async {
        if initiatedFromBackground {
            if !Preferences.isEnabled(.automaticBackgroundUpdateCheck) {
                Log.info("Automatic updates are disabled. No check will be performed.")
                return
            }

            Log.info("Automatic updates are enabled, a check will be performed.")
        }

        let versionString = await retrieveVersionFromCask(initiatedFromBackground)

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
        switch onlineVersion.version.versionCompare(currentVersion.version) {
        case .orderedAscending:
            Log.info("You are running a newer version of PHP Monitor "
                     + "(\(currentVersion.computerReadable) > \(onlineVersion.computerReadable)).")
            if !background { notifyVersionDoesNotNeedUpgrade() }
        case .orderedDescending:
            Log.info("There is a newer version (\(onlineVersion)) available! "
                     + "(\(onlineVersion.computerReadable) > \(currentVersion.computerReadable))")
            notifyAboutNewerVersion(version: onlineVersion)
        case .orderedSame:
            if currentVersion.build != nil
                && onlineVersion.build != nil
                && buildDiffers(currentVersion, onlineVersion, background) {
                return
            }

            Log.info("The installed version (\(currentVersion.computerReadable)) matches the latest release "
                     + "(\(onlineVersion.computerReadable)).")
            if !background { notifyVersionDoesNotNeedUpgrade() }
        }
    }

    private static func buildDiffers(
        _ currentVersion: AppVersion,
        _ onlineVersion: AppVersion,
        _ background: Bool
    ) -> Bool {
        if Int(onlineVersion.build!)! > Int(currentVersion.build!)! {
            Log.info("There is a newer build of PHP Monitor available! "
                     + "(\(onlineVersion.computerReadable) > \(currentVersion.computerReadable))")
            notifyAboutNewerVersion(version: onlineVersion)
            return true
        } else if Int(onlineVersion.build!)! < Int(currentVersion.build!)! {
            Log.info("You are running a newer build of PHP Monitor "
                     + "(\(currentVersion.computerReadable) > \(onlineVersion.computerReadable)).")
            if !background { notifyVersionDoesNotNeedUpgrade() }
            return true
        }

        return false
    }

    private static func notifyVersionDoesNotNeedUpgrade() {
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

    private static func notifyAboutNewerVersion(version: AppVersion) {
        let devSuffix = isDev ? "-dev" : ""
        let command = isDev ? "brew upgrade phpmon-dev" : "brew upgrade phpmon"

        Task { @MainActor in
            BetterAlert().withInformation(
                title: "updater.alerts.newer_version_available.title".localized(version.humanReadable),
                subtitle: "updater.alerts.newer_version_available.subtitle".localized,
                description: HomebrewDiagnostics.customCaskInstalled
                    ? "updater.installation_source.brew".localized(command)
                    : "updater.installation_source.direct".localized
            )
            .withPrimary(
                text: "updater.alerts.buttons.install".localized,
                action: { vc in
                    print(Self.latestCaskFileContents)
                    let sha256 = system("echo \"\(Self.latestCaskFileContents)\" | grep sha256")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "'", with: "")
                        .split(separator: " ").last ?? ""
                    let url = system("echo \"\(Self.latestCaskFileContents)\" | grep url")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "'", with: "")
                        .split(separator: " ").last ?? ""

                    print(sha256)
                    print(url)
                }
            )
            .withSecondary(
                text: "updater.alerts.buttons.release_notes".localized,
                action: { vc in
                    vc.close(with: .OK)

                    NSWorkspace.shared.open(
                        Constants.Urls.GitHubReleases.appendingPathComponent("/tag/v\(version.tagged)\(devSuffix)")
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

}
