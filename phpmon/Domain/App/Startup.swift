//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Startup {

    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     If this method returns false, there was a failed check and an alert was displayed.
     If this method returns true, then all checks succeeded and the app can continue.
     */
    func checkEnvironment() async -> Bool {
        // Do the important system setup checks
        Log.info("[ARCH] The user is running PHP Monitor with the architecture: \(App.architecture)")

        for check in self.checks {
            if await check.succeeds() {
                Log.info("[OK] \(check.name)")
                continue
            }

            // If we get here, something's gone wrong and the check has failed...
            Log.info("[FAIL] \(check.name)")
            showAlert(for: check)
            return false
        }

        // If we get here, nothing has gone wrong. That's what we want!
        initializeSwitcher()
        Log.separator(as: .info)
        Log.info("PHP Monitor has determined the application has successfully passed all checks.")
        return true
    }

    /**
     Displays an alert for a particular check. There are two types of alerts:
     - ones that require an app restart, which prompt the user to exit the app
     - ones that allow the app to continue, which allow the user to retry
     */
    private func showAlert(for check: EnvironmentCheck) {
        DispatchQueue.main.async {
            if check.requiresAppRestart {
                BetterAlert()
                    .withInformation(
                        title: check.titleText,
                        subtitle: check.subtitleText,
                        description: check.descriptionText
                    )
                    .withPrimary(text: check.buttonText, action: { _ in
                        exit(1)
                    }).show()
            }

            BetterAlert()
                .withInformation(
                    title: check.titleText,
                    subtitle: check.subtitleText,
                    description: check.descriptionText
                )
                .withPrimary(text: "OK")
                .show()
        }
    }

    /**
     Because the Switcher requires various environment guarantees, the switcher is only
     initialized when it is done working. The switcher must be initialized on the main thread.
     */
    private func initializeSwitcher() {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.initializeSwitcher()
        }
    }

    // MARK: - Check (List)

    public var checks: [EnvironmentCheck] = [
        // =================================================================================
        // The Homebrew binary must exist.
        // =================================================================================
        EnvironmentCheck(
            command: { return !FileManager.default.fileExists(atPath: Paths.brew) },
            name: "`\(Paths.brew)` exists",
            titleText: "alert.homebrew_missing.title".localized,
            subtitleText: "alert.homebrew_missing.subtitle".localized,
            descriptionText: "alert.homebrew_missing.info".localized(
                App.architecture
                    .replacingOccurrences(of: "x86_64", with: "Intel")
                    .replacingOccurrences(of: "arm64", with: "Apple Silicon"),
                Paths.brew
            ),
            buttonText: "alert.homebrew_missing.quit".localized,
            requiresAppRestart: true
        ),
        // =================================================================================
        // The PHP binary must exist.
        // =================================================================================
        EnvironmentCheck(
            command: { return !Filesystem.fileExists(Paths.php) },
            name: "`\(Paths.php)` exists",
            titleText: "startup.errors.php_binary.title".localized,
            subtitleText: "startup.errors.php_binary.subtitle".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(Paths.php)
        ),
        // =================================================================================
        // Make sure we can detect one or more PHP installations.
        // =================================================================================
        EnvironmentCheck(
            command: { return !Shell.pipe("ls \(Paths.optPath) | grep php").contains("php") },
            name: "`ls \(Paths.optPath) | grep php` returned php result",
            titleText: "startup.errors.php_opt.title".localized,
            subtitleText: "startup.errors.php_opt.subtitle".localized(
                Paths.optPath
            ),
            descriptionText: "startup.errors.php_opt.desc".localized
        ),
        // =================================================================================
        // The Valet binary must exist.
        // =================================================================================
        EnvironmentCheck(
            command: {
                return !(Filesystem.fileExists(Paths.valet) || Filesystem.fileExists("~/.composer/vendor/bin/valet"))
            },
            name: "`valet` binary exists",
            titleText: "startup.errors.valet_executable.title".localized,
            subtitleText: "startup.errors.valet_executable.subtitle".localized,
            descriptionText: "startup.errors.valet_executable.desc".localized(
                Paths.valet
            )
        ),
        // =================================================================================
        // Check if Valet and Homebrew need manual password intervention. If they do, then
        // PHP Monitor will be unable to run these commands, which prevents PHP Monitor from
        // functioning correctly. Let the user know that they need to run `valet trust`.
        // =================================================================================
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/brew").contains(Paths.brew) },
            name: "`/private/etc/sudoers.d/brew` contains brew",
            titleText: "startup.errors.sudoers_brew.title".localized,
            subtitleText: "startup.errors.sudoers_brew.subtitle".localized,
            descriptionText: "startup.errors.sudoers_brew.desc".localized
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/valet").contains(Paths.valet) },
            name: "`/private/etc/sudoers.d/valet` contains valet",
            titleText: "startup.errors.sudoers_valet.title".localized,
            subtitleText: "startup.errors.sudoers_valet.subtitle".localized,
            descriptionText: "startup.errors.sudoers_valet.desc".localized
        ),
        // =================================================================================
        // Verify if the Homebrew services are running (as root).
        // =================================================================================
        EnvironmentCheck(
            command: { return HomebrewDiagnostics.cannotLoadService() },
            name: "`sudo \(Paths.brew) services info` JSON loaded",
            titleText: "startup.errors.services_json_error.title".localized,
            subtitleText: "startup.errors.services_json_error.subtitle".localized,
            descriptionText: "startup.errors.services_json_error.desc".localized
        ),
        // =================================================================================
        // Determine that the Valet configuration JSON file is valid.
        // =================================================================================
        EnvironmentCheck(
            command: {
                // Detect additional binaries (e.g. Composer)
                Paths.shared.detectBinaryPaths()
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
        // Check for `which` alias issue
        // =================================================================================
        EnvironmentCheck(
            command: {
                return App.architecture == "x86_64"
                    && FileManager.default.fileExists(atPath: "/usr/local/bin/which")
                    && Shell.pipe("which node", requiresPath: false)
                        .contains("env: node: No such file or directory")
            },
            name: "`env: node` issue does not apply",
            titleText: "startup.errors.which_alias_issue.title".localized,
            subtitleText: "startup.errors.which_alias_issue.subtitle".localized,
            descriptionText: "startup.errors.which_alias_issue.desc".localized
        ),
        // =================================================================================
        // Determine that Valet works correctly (no issues in platform detected)
        // =================================================================================
        /*
        EnvironmentCheck(
            command: {
                return valet("--version", sudo: false)
                    .contains("Composer detected issues in your platform")
            },
            name: "`no global composer issues",
            titleText: "startup.errors.global_composer_platform_issues.title".localized,
            subtitleText: "startup.errors.global_composer_platform_issues.subtitle".localized,
            descriptionText: "startup.errors.global_composer_platform_issues.desc".localized
        ),
        */
        // =================================================================================
        // Determine the Valet version and ensure it isn't unknown.
        // =================================================================================
        EnvironmentCheck(
            command: {
                let output = valet("--version", sudo: false)
                Valet.shared.version = VersionExtractor.from(output)
                return Valet.shared.version == nil && output.contains("Laravel Valet")
            },
            name: "`valet --version` was loaded",
            titleText: "startup.errors.valet_version_unknown.title".localized,
            subtitleText: "startup.errors.valet_version_unknown.subtitle".localized,
            descriptionText: "startup.errors.valet_version_unknown.desc".localized
        )
    ]

    // MARK: - EnvironmentCheck struct

    /**
     The `EnvironmentCheck` is used to defer the execution of all of these commands until necessary.
     Checks that require an app restart will always lead to an alert and app termination shortly after.
     */
    struct EnvironmentCheck {
        let command: () async -> Bool
        let name: String
        let titleText: String
        let subtitleText: String
        let descriptionText: String
        let buttonText: String
        let requiresAppRestart: Bool

        init(
            command: @escaping () async -> Bool,
            name: String,
            titleText: String,
            subtitleText: String,
            descriptionText: String = "",
            buttonText: String = "OK",
            requiresAppRestart: Bool = false
        ) {
            self.command = command
            self.name = name
            self.titleText = titleText
            self.subtitleText = subtitleText
            self.descriptionText = descriptionText
            self.buttonText = buttonText
            self.requiresAppRestart = requiresAppRestart
        }

        public func succeeds() async -> Bool {
            return await !self.command()
        }
    }
}
