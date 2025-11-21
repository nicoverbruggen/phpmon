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

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Static Instance

    public static let shared = BrewDiagnostics(App.shared.container)

    // MARK: - Variables

    var filesystem: FileSystemProtocol {
        return container.filesystem
    }

    /**
     Determines the Homebrew taps the user has installed.
     */
    public var installedTaps: [String] = []

    // MARK: - Methods

    /**
     Load which taps are installed.
     */
    public func loadInstalledTaps() async {
        installedTaps = await container.shell
            .pipe("\(container.paths.brew) tap")
            .out
            .split(separator: "\n")
            .map { string in
                return String(string)
            }
    }

    /**
     Logs a bunch of useful information during startup.
     */
    public func logBootInformation() {
        Log.info(customCaskInstalled
             ? "[BREW] The app has been installed via Homebrew Cask."
             : "[BREW] The app has been installed directly (optimal)."
        )

        Log.info(usesNginxFullFormula
             ? "[BREW] The app will be using the `nginx-full` formula."
             : "[BREW] The app will be using the `nginx` formula."
        )
    }

    /**
     Determines whether the PHP Monitor Cask is installed.
     */
    public var customCaskInstalled: Bool {
        return installedTaps.contains("nicoverbruggen/cask")
            && filesystem.directoryExists(container.paths.caskroomPath)
    }

    /**
     Determines whether to use the regular `nginx` or `nginx-full` formula.
     */
    public var usesNginxFullFormula: Bool {
        guard let destination = try? filesystem
            .getDestinationOfSymlink("\(container.paths.binPath)/nginx") else { return false }

        // Verify that the `nginx` binary is symlinked to a directory that includes `nginx-full`.
        return destination.contains("/nginx-full/")
    }

    /**
     It is possible to have outdated symlinks for PHP installations. This can mean that certain PHP installations
     are going to be reported incorrectly (e.g. `php@8.2` links to an installation in a `8.3` folder after an upgrade).

     To ensure this does not cause issues, PHP Monitor will automatically remove all incorrect PHP symlinks.
     */
    public func checkForOutdatedPhpInstallationSymlinks() async {
        // Set up a regular expression
        let regex = try! NSRegularExpression(pattern: "^php@[0-9]+\\.[0-9]+$", options: .caseInsensitive)

        // Check for incorrect versions
        if let contents = try? filesystem.getShallowContentsOfDirectory("\(container.paths.optPath)")
            .filter({
                let range = NSRange($0.startIndex..., in: $0)
                return regex.firstMatch(in: $0, options: [], range: range) != nil
            }) {

            for symlink in contents {
                let version = symlink.replacing("php@", with: "")
                if let destination = try? filesystem.getDestinationOfSymlink("\(container.paths.optPath)/\(symlink)") {
                    if !destination.contains("Cellar/php/\(version)")
                        && !destination.contains("Cellar/php@\(version)") {
                        Log.err("Symlink for \(symlink) is incorrect. Removing...")
                        do {
                            try filesystem.remove("\(container.paths.optPath)/\(symlink)")
                            Log.info("Incorrect symlink for \(symlink) has been successfully removed.")
                        } catch {
                            Log.err("Symlink for \(symlink) was incorrect but could not be removed!")
                        }
                    }
                } else {
                    Log.warn("Could not read symlink at: \(container.paths.optPath)/\(symlink)! Symlink check skipped.")
                }
            }
        }
    }

    /**
     It is possible to upgrade PHP, but forget running `valet install`.
     This results in a scenario where a rogue www.conf file exists.
     */
    public func checkForValetMisconfiguration() async {
        Log.info("Checking for PHP-FPM issues with Valet...")

        guard let install = container.phpEnvs.phpInstall else {
            Log.info("Will skip check for issues if no PHP version is linked.")
            return
        }

        // We'll need to know what the primary PHP version is
        let primary = install.version.short

        // Versions to be handled
        let switcher = InternalSwitcher(container)

        for version in switcher.getVersionsToBeHandled(primary)
        where await switcher.ensureValetConfigurationIsValidForPhpVersion(version) {
            Log.info("One or more fixes were applied for PHP \(version)!")
            await switcher.unlinkAndStopPhpVersion(version)
            await switcher.linkAndStartPhpVersion(version, primary: version == primary)
        }
    }

    public func verifyThirdPartyTaps() async {
        let requiredTaps = [
            "shivammathur/php",
            "shivammathur/extensions"
        ]

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
     In order to see if we support the --json syntax, we'll query nginx.
     If the JSON response cannot be parsed, Homebrew is probably out of date.
     */
    public func cannotLoadService(_ name: String) async -> Bool {
        let nginxJson = await container.shell
            .pipe("sudo \(container.paths.brew) services info \(name) --json")
            .out

        let serviceInfo = try? JSONDecoder().decode(
            [HomebrewService].self,
            from: nginxJson.data(using: .utf8)!
        )

        return serviceInfo == nil
    }
}
