//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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
    func checkEnvironment() async -> Bool
    {
        // Do the important system setup checks
        Log.info("[ARCH] The user is running PHP Monitor with the architecture: \(App.architecture)")
        
        for check in self.checks {
            if await check.succeeds() {
                Log.info("[OK] \(check.name)")
                continue
            }
            
            // If we get here, something's gone wrong and the check has failed
            Log.info("[FAIL] \(check.name)")
            showAlert(for: check)
            return false
        }
        
        // If we get here, nothing has gone wrong. That's what we want!
        initializeSwitcher()
        Log.info("==================================")
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
                Alert.notify(
                    message: check.titleText,
                    info: check.descriptionText,
                    button: check.buttonText,
                    style: .critical
                )
                exit(1)
            }
            
            Alert.notify(
                message: check.titleText,
                info: check.descriptionText,
                style: .critical
            )
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
        EnvironmentCheck(
            command: { return !FileManager.default.fileExists(atPath: Paths.brew) },
            name: "`\(Paths.brew)` exists",
            titleText: "alert.homebrew_missing.title".localized,
            descriptionText: "alert.homebrew_missing.info".localized(
                App.architecture
                    .replacingOccurrences(of: "x86_64", with: "Intel")
                    .replacingOccurrences(of: "arm64", with: "Apple Silicon"),
                Paths.brew
            ),
            buttonText: "alert.homebrew_missing.quit".localized,
            requiresAppRestart: true
        ),
        EnvironmentCheck(
            command: { return !Filesystem.fileExists(Paths.php) },
            name: "`\(Paths.php)` exists",
            titleText: "startup.errors.php_binary.title".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                Paths.php
            )
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("ls \(Paths.optPath) | grep php").contains("php") },
            name: "`ls \(Paths.optPath) | grep php` returned php result",
            titleText: "startup.errors.php_opt.title".localized,
            descriptionText: "startup.errors.php_opt.desc".localized(
                Paths.optPath
            )
        ),
        EnvironmentCheck(
            command: {
                return !(Filesystem.fileExists(Paths.valet)
                         || Filesystem.fileExists("~/.composer/vendor/bin/valet"))
            },
            name: "`valet` binary exists",
            titleText: "startup.errors.valet_executable.title".localized,
            descriptionText: "startup.errors.valet_executable.desc".localized(
                Paths.valet
            )
        ),
        EnvironmentCheck(
            command: { return HomebrewDiagnostics.cannotLoadService() },
            name: "`sudo \(Paths.brew) services info` JSON loaded",
            titleText: "startup.errors.services_json_error.title".localized,
            descriptionText: "startup.errors.services_json_error.desc".localized
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/brew").contains(Paths.brew) },
            name: "`/private/etc/sudoers.d/brew` contains brew",
            titleText: "startup.errors.sudoers_brew.title".localized,
            descriptionText: "startup.errors.sudoers_brew.desc".localized
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/valet").contains(Paths.valet) },
            name: "`/private/etc/sudoers.d/valet` contains valet",
            titleText: "startup.errors.sudoers_valet.title".localized,
            descriptionText: "startup.errors.sudoers_valet.desc".localized
        ),
        EnvironmentCheck(
            command: {
                // Determine the Valet version only AFTER confirming the correct permission is in place
                // or otherwise this command will never return a valid version number
                Valet.shared.version = VersionExtractor.from(valet("--version", sudo: false))
                return Valet.shared.version == nil
            },
            name: "`valet --version` was loaded",
            titleText: "startup.errors.valet_version_unknown.title".localized,
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
        let descriptionText: String
        let buttonText: String
        let requiresAppRestart: Bool
        
        init(
            command: @escaping () async -> Bool,
            name: String,
            titleText: String,
            descriptionText: String,
            buttonText: String = "OK",
            requiresAppRestart: Bool = false
        ) {
            self.command = command
            self.name = name
            self.titleText = titleText
            self.descriptionText = descriptionText
            self.buttonText = buttonText
            self.requiresAppRestart = requiresAppRestart
        }
        
        public func succeeds() async -> Bool {
            return await !self.command()
        }
    }
}
