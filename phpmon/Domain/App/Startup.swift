//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import NVAlert

class Startup {
    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     If this method returns false, there was a failed check and an alert was displayed.
     If this method returns true, then all checks succeeded and the app can continue.
     */
    func checkEnvironment() async -> Bool {
        // Do the important system setup checks
        Log.info("The user is running PHP Monitor with the architecture: \(App.architecture)")

        // Set up a "background" timer on the main thread
        Task { @MainActor in
            startStartupTimer()
        }

        for group in self.groups {
            if group.condition() {
                Log.info("Now running \(group.checks.count) \(group.name) checks!")
                for check in group.checks {
                    let start = Measurement()
                    if await check.succeeds() {
                        Log.info("[PASS] \(check.name) (\(start.milliseconds) ms)")
                        continue
                    }

                    // If we get here, something's gone wrong and the check has failed...
                    Log.info("[FAIL] \(check.name) (\(start.milliseconds) ms)")
                    await showAlert(for: check)
                    return false
                }
            } else {
                Log.info("Skipping \(group.name) checks!")
            }
        }

        // If we get here, nothing has gone wrong. That's what we want!
        initializeSwitcher()
        Log.info("PHP Monitor has determined the application has successfully passed all checks.")

        Log.separator(as: .info)
        return true
    }

    /**
     Displays an alert for a particular check. There are two types of alerts:
     - ones that require an app restart, which prompt the user to exit the app
     - ones that allow the app to continue, which allow the user to retry
     */
    @MainActor private func showAlert(for check: EnvironmentCheck) {
        if check.requiresAppRestart {
            NVAlert()
                .withInformation(
                    title: check.titleText,
                    subtitle: check.subtitleText,
                    description: check.descriptionText
                )
                .withPrimary(text: check.buttonText, action: { _ in
                    exit(1)
                }).show()
        }

        NVAlert()
            .withInformation(
                title: check.titleText,
                subtitle: check.subtitleText,
                description: check.descriptionText
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    /**
     Because the Switcher requires various environment guarantees, the switcher is only
     initialized when it is done working. The switcher must be initialized on the main thread.
     */
    private func initializeSwitcher() {
        Task { @MainActor in
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.initializeSwitcher()
        }
    }

    // MARK: - Check (List)

    public var groups: [EnvironmentCheckGroup] = [
        EnvironmentCheckGroup(name: "core", condition: { return true }, checks: [
            // =================================================================================
            // The Homebrew binary must exist.
            // =================================================================================
            EnvironmentCheck(
                command: { return !App.shared.container.filesystem.fileExists(App.shared.container.paths.brew) },
                name: "`\(App.shared.container.paths.brew)` exists",
                titleText: "alert.homebrew_missing.title".localized,
                subtitleText: "alert.homebrew_missing.subtitle".localized,
                descriptionText: "alert.homebrew_missing.info".localized(
                    App.architecture
                        .replacingOccurrences(of: "x86_64", with: "Intel")
                        .replacingOccurrences(of: "arm64", with: "Apple Silicon"),
                    App.shared.container.paths.brew
                ),
                buttonText: "alert.homebrew_missing.quit".localized,
                requiresAppRestart: true
            ),
            // =================================================================================
            // Make sure we can detect one or more PHP installations.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return await !App.shared.container.shell.pipe("ls \(App.shared.container.paths.optPath) | grep php").out.contains("php")
                },
                name: "`ls \(App.shared.container.paths.optPath) | grep php` returned php result",
                titleText: "startup.errors.php_opt.title".localized,
                subtitleText: "startup.errors.php_opt.subtitle".localized(
                    App.shared.container.paths.optPath
                ),
                descriptionText: "startup.errors.php_opt.desc".localized
            )
        ]),
        EnvironmentCheckGroup(name: "valet", condition: { return Valet.installed }, checks: [
            // =================================================================================
            // The PHP binary must exist.
            // =================================================================================
            EnvironmentCheck(
                command: { return !App.shared.container.filesystem.fileExists(App.shared.container.paths.php) },
                name: "`\(App.shared.container.paths.php)` exists",
                titleText: "startup.errors.php_binary.title".localized,
                subtitleText: "startup.errors.php_binary.subtitle".localized,
                descriptionText: "startup.errors.php_binary.desc".localized(App.shared.container.paths.php)
            ),
            // =================================================================================
            // Ensure that the main PHP installation is not broken.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return await App.shared.container.shell.pipe("\(App.shared.container.paths.binPath)/php -v").err
                        .contains("Library not loaded")
                },
                name: "no `dyld` issue (`Library not loaded`) detected",
                titleText: "startup.errors.dyld_library.title".localized,
                subtitleText: "startup.errors.dyld_library.subtitle".localized(
                    App.shared.container.paths.optPath
                ),
                descriptionText: "startup.errors.dyld_library.desc".localized
            ),
            // =================================================================================
            // The Valet binary must exist.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return !(App.shared.container.filesystem.fileExists(App.shared.container.paths.valet)
                             || App.shared.container.filesystem.fileExists("~/.composer/vendor/bin/valet"))
                },
                name: "`valet` binary exists",
                titleText: "startup.errors.valet_executable.title".localized,
                subtitleText: "startup.errors.valet_executable.subtitle".localized,
                descriptionText: "startup.errors.valet_executable.desc".localized(
                    App.shared.container.paths.valet
                )
            ),
            // =================================================================================
            // Check if Valet and Homebrew need manual password intervention. If they do, then
            // PHP Monitor will be unable to run these commands, which prevents PHP Monitor from
            // functioning correctly. Let the user know that they need to run `valet trust`.
            // =================================================================================
            EnvironmentCheck(
                command: { return await !App.shared.container.shell.pipe("cat /private/etc/sudoers.d/brew").out.contains(App.shared.container.paths.brew) },
                name: "`/private/etc/sudoers.d/brew` contains brew",
                titleText: "startup.errors.sudoers_brew.title".localized,
                subtitleText: "startup.errors.sudoers_brew.subtitle".localized,
                descriptionText: "startup.errors.sudoers_brew.desc".localized
            ),
            EnvironmentCheck(
                command: { return await !App.shared.container.shell.pipe("cat /private/etc/sudoers.d/valet").out.contains(App.shared.container.paths.valet) },
                name: "`/private/etc/sudoers.d/valet` contains valet",
                titleText: "startup.errors.sudoers_valet.title".localized,
                subtitleText: "startup.errors.sudoers_valet.subtitle".localized,
                descriptionText: "startup.errors.sudoers_valet.desc".localized
            ),
            // =================================================================================
            // Determine that Valet is installed
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return !App.shared.container.filesystem.directoryExists("~/.config/valet")
                },
                name: "`.config/valet` not empty (Valet installed)",
                titleText: "startup.errors.valet_not_installed.title".localized,
                subtitleText: "startup.errors.valet_not_installed.subtitle".localized,
                descriptionText: "startup.errors.valet_not_installed.desc".localized
            ),
            // =================================================================================
            // Determine that the Valet configuration JSON file is valid.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    // Detect additional binaries (e.g. Composer)
                    App.shared.container.paths.detectBinaryPaths()
                    // Load the configuration file (config.json)
                    Valet.shared.loadConfiguration()
                    // This check fails when the config is nil
                    return Valet.shared.config == nil
                },
                name: "`config.json` was valid",
                titleText: "startup.errors.valet_json_invalid.title".localized,
                subtitleText: "startup.errors.valet_json_invalid.subtitle".localized,
                descriptionText: "startup.errors.valet_json_invalid.desc".localized
            ),
            // =================================================================================
            // Verify if the Homebrew services are running (as root).
            // =================================================================================
            EnvironmentCheck(
                command: {
                    await BrewDiagnostics.shared.loadInstalledTaps()
                    return await BrewDiagnostics.shared.cannotLoadService("dnsmasq")
                },
                name: "`sudo \(App.shared.container.paths.brew) services info` JSON loaded",
                titleText: "startup.errors.services_json_error.title".localized,
                subtitleText: "startup.errors.services_json_error.subtitle".localized,
                descriptionText: "startup.errors.services_json_error.desc".localized
            ),
            // =================================================================================
            // Check for `which` alias issue
            // =================================================================================
            EnvironmentCheck(
                command: {
                    let nodePath = await App.shared.container.shell.pipe("which node").out
                    return App.architecture == "x86_64"
                    && App.shared.container.filesystem.fileExists("/usr/local/bin/which")
                    && nodePath.contains("env: node: No such file or directory")
                },
                name: "`env: node` issue does not apply",
                titleText: "startup.errors.which_alias_issue.title".localized,
                subtitleText: "startup.errors.which_alias_issue.subtitle".localized,
                descriptionText: "startup.errors.which_alias_issue.desc".localized
            ),
            // =================================================================================
            // Determine that Laravel Herd is not running (may cause conflicts)
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return NSWorkspace.shared.runningApplications.contains(where: { app in
                        return app.bundleIdentifier == "de.beyondco.herd"
                    })
                },
                name: "Herd is not running",
                titleText: "startup.errors.herd_running.title".localized,
                subtitleText: "startup.errors.herd_running.subtitle".localized,
                descriptionText: "startup.errors.herd_running.desc".localized
            ),
            // =================================================================================
            // Determine that Valet works correctly (no issues in platform detected)
            // =================================================================================
            EnvironmentCheck(
                command: {
                    return await App.shared.container.shell.pipe("valet --version").out
                        .contains("Composer detected issues in your platform")
                },
                name: "no global composer issues",
                titleText: "startup.errors.global_composer_platform_issues.title".localized,
                subtitleText: "startup.errors.global_composer_platform_issues.subtitle".localized,
                descriptionText: "startup.errors.global_composer_platform_issues.desc".localized
            ),
            // =================================================================================
            // Determine the Valet version and ensure it isn't unknown.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    await Valet.shared.updateVersionNumber()
                    return Valet.shared.version == nil
                },
                name: "`valet --version` was loaded",
                titleText: "startup.errors.valet_version_unknown.title".localized,
                subtitleText: "startup.errors.valet_version_unknown.subtitle".localized,
                descriptionText: "startup.errors.valet_version_unknown.desc".localized
            ),
            // =================================================================================
            // Ensure the Valet version is supported.
            // =================================================================================
            EnvironmentCheck(
                command: {
                    // We currently support Valet 2, 3 or 4. Any other version should get an alert.
                    return ![2, 3, 4].contains(Valet.shared.version?.major)
                },
                name: "valet version is supported",
                titleText: "startup.errors.valet_version_not_supported.title".localized,
                subtitleText: "startup.errors.valet_version_not_supported.subtitle".localized,
                descriptionText: "startup.errors.valet_version_not_supported.desc".localized
            )
        ])
    ]
}
