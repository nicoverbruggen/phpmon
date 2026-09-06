//
//  BrewDiagnostics.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert
import os

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

     Backed by an `OSAllocatedUnfairLock` box: this is reassigned from `loadInstalledTaps()`
     (which runs off the main thread) and read from several async contexts, so access must
     be synchronized to avoid a data race on the array buffer.
     */
    private let _installedTaps = OSAllocatedUnfairLock<[String]>(initialState: [])
    // `nonisolated`: reassigned off-main by `loadInstalledTaps()` and read from async
    // contexts; the lock box keeps this data-race free across isolation domains.
    public nonisolated var installedTaps: [String] {
        get { _installedTaps.withLock { $0 } }
        set { _installedTaps.withLock { $0 = newValue } }
    }

    /**
     Determines the Homebrew taps the user has explicitly trusted.

     Backed by an `OSAllocatedUnfairLock` box for the same reason as `installedTaps`.
     */
    private let _trustedTaps = OSAllocatedUnfairLock<[String]>(initialState: [])
    public nonisolated var trustedTaps: [String] {
        get { _trustedTaps.withLock { $0 } }
        set { _trustedTaps.withLock { $0 = newValue } }
    }

    private var hasLoadedTrustedTaps = false
    private var cachedSupportsTapTrust: Bool?

    public static let requiredPhpTaps = [
        Constants.Taps.php,
        Constants.Taps.extensions
    ]

    // MARK: - Methods

    /**
     Load which taps are installed.
     */
    public nonisolated func loadInstalledTaps() async {
        installedTaps = await container.shell
            .pipe("\(container.paths.brew) tap")
            .out
            .split(separator: "\n")
            .map { string in
                return String(string)
            }
    }

    /**
     Determines whether this Homebrew installation supports `brew trust`.
     */
    public func supportsTapTrust() async -> Bool {
        if let cachedSupportsTapTrust {
            return cachedSupportsTapTrust
        }

        let output = await container.shell.pipe("\(container.paths.brew) help trust")
        let response = "\(output.out)\n\(output.err)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let supportsTapTrust = response.contains("usage: brew trust")
            || response.contains("trust non-official tap")
            || response.contains("--tap")

        cachedSupportsTapTrust = supportsTapTrust

        if supportsTapTrust {
            Log.info("[BREW] This Homebrew installation supports `brew trust`.")
        } else {
            Log.info("[BREW] This Homebrew installation does not support `brew trust`; tap trust checks are skipped.")
        }

        return supportsTapTrust
    }

    /**
     Load which taps are explicitly trusted.
     */
    public func loadTrustedTaps() async {
        guard await supportsTapTrust() else {
            trustedTaps = []
            hasLoadedTrustedTaps = true
            return
        }

        trustedTaps = await container.shell
            .pipe("\(container.paths.brew) trust --tap")
            .out
            .split(separator: "\n")
            .map { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { line in
                line.contains("/")
            }

        hasLoadedTrustedTaps = true
    }

    public func tapRequiresTrust(_ tap: String) async -> Bool {
        guard await supportsTapTrust() else {
            return false
        }

        if !hasLoadedTrustedTaps {
            await loadTrustedTaps()
        }

        return installedTaps.contains(tap) && !trustedTaps.contains(tap)
    }

    public func untrustedRequiredPhpTaps() async -> [String] {
        guard await supportsTapTrust() else {
            return []
        }

        if !hasLoadedTrustedTaps {
            await loadTrustedTaps()
        }

        return Self.requiredPhpTaps.filter { tap in
            installedTaps.contains(tap) && !trustedTaps.contains(tap)
        }
    }

    public func missingRequiredPhpTaps() -> [String] {
        return Self.requiredPhpTaps.filter { tap in
            !installedTaps.contains(tap)
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
        // Pure filesystem work against nonisolated leaves — run it on the
        // concurrent pool so the directory scan never blocks the main actor.
        await offMain { [container, filesystem] in
            // Set up a regular expression
            let regex = try! NSRegularExpression(pattern: "^php@[0-9]+\\.[0-9]+$", options: .caseInsensitive)

            // Check for incorrect versions
            guard let contents = try? filesystem.getShallowContentsOfDirectory("\(container.paths.optPath)")
                .filter({
                    let range = NSRange($0.startIndex..., in: $0)
                    return regex.firstMatch(in: $0, options: [], range: range) != nil
                }) else {
                return
            }

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

        guard let version = container.phpEnvs.phpInstall?.version else {
            Log.info("Will skip check for issues if no PHP version is linked.")
            return
        }

        // We'll need to know what the primary PHP version is
        let primary = version.short

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
        await loadInstalledTaps()
        await loadTrustedTaps()

        // Check the status of the installed taps
        for tap in Self.requiredPhpTaps {
            if await tapRequiresTrust(tap) {
                Log.warn("`\(tap)` is installed, but not trusted. It will be noted in warnings.")
            } else if installedTaps.contains(tap) {
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
