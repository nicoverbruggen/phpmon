//
//  AliasConflict.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class HomebrewDiagnostics {
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
     Determines whether the PHP Monitor Cask is installed.
     */
    public static var customCaskInstalled: Bool = {
        return installedTaps.contains("nicoverbruggen/cask")
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
    public static func checkForPhpFpmPoolConflicts() {
        Log.info("Checking for PHP-FPM pool conflicts...")

        // We'll need to know what the primary PHP version is
        let primary = PhpEnv.shared.currentInstall.version.short

        // Versions to be handled
        let switcher = InternalSwitcher()
        var versions = switcher.getVersionsToBeHandled(primary)

        versions = versions.filter { version in
            return switcher.requiresDisablingOfDefaultPhpFpmPool(version)
        }

        if versions.isEmpty {
            Log.info("No PHP-FPM pools need to be fixed. All OK.")
        }

        versions.forEach { version in
            Task { // Fix each pool concurrently (but perform the tasks sequentially)
                await switcher.disableDefaultPhpFpmPool(version)
                await switcher.stopPhpVersion(version)
                await switcher.startPhpVersion(version, primary: version == primary)
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

            if tapPhp.version != PhpEnv.brewPhpAlias {
                Log.warn("The `php` formula alias seems to be the different between the tap and core. "
                         + "This could be a problem!")
                Log.info("Determining whether both of these versions are installed...")

                let bothInstalled = PhpEnv.shared.availablePhpVersions.contains(tapPhp.version)
                    && PhpEnv.shared.availablePhpVersions.contains(PhpEnv.brewPhpAlias)

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
            BetterAlert()
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
