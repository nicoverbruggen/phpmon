//
//  BrewDiagnostics.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert

class BrewDiagnostics {
    /**
     Determines the Homebrew taps the user has installed.
     */
    public static var installedTaps: [String] = []

    /**
     Load which taps are installed.
     */
    public static func loadInstalledTaps() async {
        installedTaps = await Shell
            .pipe("\(Paths.brew) tap")
            .out
            .split(separator: "\n")
            .map { string in
                return String(string)
            }
    }

    /**
     Logs a bunch of useful information during startup.
     */
    public static func logBootInformation() {
        Log.info(BrewDiagnostics.customCaskInstalled
             ? "[BREW] The app has been installed via Homebrew Cask."
             : "[BREW] The app has been installed directly (optimal)."
        )

        Log.info(BrewDiagnostics.usesNginxFullFormula
             ? "[BREW] The app will be using the `nginx-full` formula."
             : "[BREW] The app will be using the `nginx` formula."
        )
    }

    /**
     Determines whether the PHP Monitor Cask is installed.
     */
    public static var customCaskInstalled: Bool = {
        return installedTaps.contains("nicoverbruggen/cask")
            && FileSystem.directoryExists(Paths.caskroomPath)
    }()

    /**
     Determines whether to use the regular `nginx` or `nginx-full` formula.
     */
    public static var usesNginxFullFormula: Bool = {
        guard let destination = try? FileManager.default
            .destinationOfSymbolicLink(atPath: "\(Paths.binPath)/nginx") else { return false }

        // Verify that the `nginx` binary is symlinked to a directory that includes `nginx-full`.
        return destination.contains("/nginx-full/")
    }()

    /**
     It is possible to have outdated symlinks for PHP installations. This can mean that certain PHP installations
     are going to be reported incorrectly (e.g. `php@8.2` links to an installation in a `8.3` folder after an upgrade).

     To ensure this does not cause issues, PHP Monitor will automatically remove all incorrect PHP symlinks.
     */
    public static func checkForOutdatedPhpInstallationSymlinks() async {
        // Set up a regular expression
        let regex = try! NSRegularExpression(pattern: "^php@[0-9]+\\.[0-9]+$", options: .caseInsensitive)

        // Check for incorrect versions
        if let contents = try? FileSystem.getShallowContentsOfDirectory("\(Paths.optPath)")
            .filter({
                let range = NSRange($0.startIndex..., in: $0)
                return regex.firstMatch(in: $0, options: [], range: range) != nil
            }) {

            for symlink in contents {
                let version = symlink.replacingOccurrences(of: "php@", with: "")
                if let destination = try? FileSystem.getDestinationOfSymlink("\(Paths.optPath)/\(symlink)") {
                    if !destination.contains("Cellar/php/\(version)")
                        && !destination.contains("Cellar/php@\(version)") {
                        Log.err("Symlink for \(symlink) is incorrect. Removing...")
                        do {
                            try FileSystem.remove("\(Paths.optPath)/\(symlink)")
                            Log.info("Incorrect symlink for \(symlink) has been successfully removed.")
                        } catch {
                            Log.err("Symlink for \(symlink) was incorrect but could not be removed!")
                        }
                    }
                } else {
                    Log.warn("Could not read symlink at: \(Paths.optPath)/\(symlink)! Symlink check skipped.")
                }
            }
        }
    }

    /**
     It is possible to have the `shivammathur/php` tap installed, and for the core homebrew information to be outdated.
     This will then result in two different aliases claiming to point to the same formula (`php`).
     This will break all linking functionality in PHP Monitor, and the user needs to be informed of this.

     This check only needs to be performed if the `shivammathur/php` tap is active.
     */
    public static func checkForCaskConflict() async {
        if await hasAliasConflict() {
            presentAlertAboutConflict()
        }
    }

    /**
     It is possible to upgrade PHP, but forget running `valet install`.
     This results in a scenario where a rogue www.conf file exists.
     */
    public static func checkForValetMisconfiguration() async {
        Log.info("Checking for PHP-FPM issues with Valet...")

        guard let install = PhpEnvironments.phpInstall else {
            Log.info("Will skip check for issues if no PHP version is linked.")
            return
        }

        // We'll need to know what the primary PHP version is
        let primary = install.version.short

        // Versions to be handled
        let switcher = InternalSwitcher()

        for version in switcher.getVersionsToBeHandled(primary)
        where await switcher.ensureValetConfigurationIsValidForPhpVersion(version) {
            Log.info("One or more fixes were applied for PHP \(version)!")
            await switcher.unlinkAndStopPhpVersion(version)
            await switcher.linkAndStartPhpVersion(version, primary: version == primary)
        }
    }

    public static func verifyAndInstallThirdPartyTaps() async {
        let requiredTaps = [
            "shivammathur/php",
            "shivammathur/extensions"
        ]

        var requiredInstall = false

        // Install required taps if missing (if possible)
        for tap in requiredTaps where !installedTaps.contains(tap) {
            await Shell.quiet("brew tap \(tap)")
            requiredInstall = true
        }

        // Reload the list of taps after installing
        if requiredInstall {
            await loadInstalledTaps()
        }

        // Check the status of the installed taps
        for tap in requiredTaps {
            if installedTaps.contains(tap) {
                Log.info("As expected, `\(tap)` is installed!")
            } else {
                Log.warn("`\(tap)` does not appear to be installed, will be noted in warnings.")
            }
        }
    }

    /**
     Check if the alias conflict as documented in `checkForCaskConflict` actually occurred.
     */
    private static func hasAliasConflict() async -> Bool {
        let tapAlias = await Shell.pipe("brew info shivammathur/php/php --json").out

        if tapAlias.contains("brew tap shivammathur/php") || tapAlias.contains("Error") || tapAlias.isEmpty {
            Log.info("The user does not appear to have tapped: shivammathur/php")
            return false
        } else {
            Log.info("The user DOES have the following tapped: shivammathur/php")
            Log.info("Checking for `php` formula conflicts...")

            let tapPhp = try! JSONDecoder().decode(
                [HomebrewPackage].self,
                from: tapAlias.data(using: .utf8)!
            ).first!

            if tapPhp.version != PhpEnvironments.brewPhpAlias {
                Log.warn("The `php` formula alias seems to be the different between the tap and core. "
                         + "This could be a problem!")
                Log.info("Determining whether both of these versions are installed...")

                let bothInstalled = PhpEnvironments.shared.availablePhpVersions.contains(tapPhp.version)
                    && PhpEnvironments.shared.availablePhpVersions.contains(PhpEnvironments.brewPhpAlias)

                if bothInstalled {
                    Log.warn("Both conflicting aliases seem to be installed, warning the user!")
                } else {
                    Log.info("Conflicting aliases are not both installed, seems fine!")
                }

                return bothInstalled
            }

            Log.info("All seems to be OK. No conflicts, both are PHP \(tapPhp.version).")

            return false
        }
    }

    /**
     Show this alert in case the tapped Cask does cause issues because of the conflict.
     */
    private static func presentAlertAboutConflict() {
        Task { @MainActor in
            NVAlert()
                .withInformation(
                    title: "alert.php_alias_conflict.title".localized,
                    subtitle: "alert.php_alias_conflict.info".localized
                )
                .withPrimary(text: "generic.ok".localized)
                .show()
        }
    }

    /**
     In order to see if we support the --json syntax, we'll query nginx.
     If the JSON response cannot be parsed, Homebrew is probably out of date.
     */
    public static func cannotLoadService(_ name: String) async -> Bool {
        let nginxJson = await Shell
            .pipe("sudo \(Paths.brew) services info \(name) --json")
            .out

        let serviceInfo = try? JSONDecoder().decode(
            [HomebrewService].self,
            from: nginxJson.data(using: .utf8)!
        )

        return serviceInfo == nil
    }
}
