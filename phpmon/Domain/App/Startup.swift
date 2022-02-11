//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Startup {
    
    public var checks: [EnvironmentCheck] = [
        EnvironmentCheck(
            command: { return !FileManager.default.fileExists(atPath: Paths.brew) },
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
            command: { return !Shell.fileExists(Paths.php) },
            titleText: "startup.errors.php_binary.title".localized,
            descriptionText: "startup.errors.php_binary.desc".localized(
                Paths.php
            )
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("ls \(Paths.optPath) | grep php").contains("php") },
            titleText: "startup.errors.php_opt.title".localized,
            descriptionText: "startup.errors.php_opt.desc".localized(
                Paths.optPath
            )
        ),
        EnvironmentCheck(
            command: {
                return !(Shell.fileExists(Paths.valet)
                         || Shell.fileExists("~/.composer/vendor/bin/valet"))
            },
            titleText: "startup.errors.valet_executable.title".localized,
            descriptionText: "startup.errors.valet_executable.desc".localized(
                Paths.valet
            )
        ),
        EnvironmentCheck(
            command: { return HomebrewDiagnostics.cannotLoadService() },
            titleText: "startup.errors.services_json_error.title".localized,
            descriptionText: "startup.errors.services_json_error.desc".localized
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/brew").contains(Paths.brew) },
            titleText: "startup.errors.sudoers_brew.title".localized,
            descriptionText: "startup.errors.sudoers_brew.desc".localized
        ),
        EnvironmentCheck(
            command: { return !Shell.pipe("cat /private/etc/sudoers.d/valet").contains(Paths.valet) },
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
            titleText: "startup.errors.valet_version_unknown.title".localized,
            descriptionText: "startup.errors.valet_version_unknown.desc".localized
        )
    ]
    
    public var failed: Bool = false
    
    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     - Parameter success: Callback that is fired if the application can proceed with launch
     - Parameter failure: Callback that is fired if the application must retry launch
     */
    func checkEnvironment(success: @escaping () -> Void, failure: @escaping () -> Void)
    {
        // Do the important system setup checks
        Log.info("The user is running PHP Monitor with the architecture: \(App.architecture)")
        
        for check in self.checks {
            let failureCondition = check.command()
            
            if !failureCondition {
                continue
            }
            
            failed = true
            
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
        
        if failed {
            failure()
            return
        }
        
        initializeSwitcher()
        Log.info("PHP Monitor has determined the application has successfully passed all checks.")
        success()
    }
    
    /**
     Because the Switcher requires various environment guarantees, the switcher is only
     initialized when it is done working.
     */
    private func initializeSwitcher() {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.initializeSwitcher()
        }
    }
    
    // MARK: - EnvironmentCheck struct
    
    /**
     The `EnvironmentCheck` is used to defer the execution of all of these commands until necessary.
     Checks that require an app restart will always lead to an alert and app termination shortly after.
     */
    struct EnvironmentCheck {
        let command: () -> Bool
        let titleText: String
        let descriptionText: String
        let buttonText: String
        let requiresAppRestart: Bool
        
        init(
            command: @escaping () -> Bool,
            titleText: String,
            descriptionText: String,
            buttonText: String = "OK",
            requiresAppRestart: Bool = false
        ) {
            self.command = command
            self.titleText = titleText
            self.descriptionText = descriptionText
            self.buttonText = buttonText
            self.requiresAppRestart = requiresAppRestart
        }
    }
}
