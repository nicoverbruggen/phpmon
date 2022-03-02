//
//  MainMenu+Startup.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension MainMenu {
    /**
     Kick off the startup of the rendering of the main menu.
     */
    func startup() async {
        // Start with the icon
        DispatchQueue.main.async {
            self.setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
        }
        
        if await Startup().checkEnvironment() {
            self.onEnvironmentPass()
        } else {
            self.onEnvironmentFail()
        }
    }
    
    /**
     When the environment is all clear and the app can run, let's go.
     */
    private func onEnvironmentPass() {
        PhpEnv.detectPhpVersions()
        
        if HomebrewDiagnostics.hasAliasConflict() {
            DispatchQueue.main.async {
                BetterAlert()
                    .withInformation(
                        title: "alert.php_alias_conflict.title".localized,
                        subtitle: "alert.php_alias_conflict.info".localized
                    )
                    .withPrimary(text: "OK")
                    .show()
            }
        }
        
        updatePhpVersionInStatusBar()
        
        Log.info("Determining broken PHP-FPM...")
        // Attempt to find out if PHP-FPM is broken
        let installation = PhpEnv.phpInstall
        installation.notifyAboutBrokenPhpFpm()
        
        // Set up the config watchers on launch (these are automatically updated via delegate methods if the user switches)
        Log.info("Setting up watchers...")
        App.shared.handlePhpConfigWatcher()
        
        // Detect applications (preset + custom)
        Log.info("Detecting applications...")
        App.shared.detectedApplications = Application.detectPresetApplications()
        let customApps = Preferences.custom.scanApps.map { appName in
            return Application(appName, .user_supplied)
        }.filter { app in
            return app.isInstalled()
        }
        App.shared.detectedApplications.append(contentsOf: customApps)
        let appNames = App.shared.detectedApplications.map { app in
            return app.name
        }
        Log.info("Detected applications: \(appNames)")
        
        // Load the global hotkey
        App.shared.loadGlobalHotkey()
        
        // Attempt to find out more info about Valet
        if Valet.shared.version != nil {
            Log.info("PHP Monitor has extracted the version number of Valet: \(Valet.shared.version!)")
        }
        
        Paths.shared.detectBinaryPaths()
        
        Valet.shared.loadConfiguration()
        Valet.shared.validateVersion()
        Valet.shared.startPreloadingSites()
        
        if (Valet.shared.config.tld != "test") {
            DispatchQueue.main.async {
                BetterAlert().withInformation(
                    title: "alert.warnings.tld_issue.title".localized,
                    subtitle: "alert.warnings.tld_issue.subtitle".localized,
                    description: "alert.warnings.tld_issue.description".localized
                ).withPrimary(text: "OK").show()
            }
        }
        
        NotificationCenter.default.post(name: Events.ServicesUpdated, object: nil)
        
        Log.info("PHP Monitor is ready to serve!")
        
        // Schedule a request to fetch the PHP version every 60 seconds
        DispatchQueue.main.async { [self] in
            App.shared.timer = Timer.scheduledTimer(
                timeInterval: 60,
                target: self,
                selector: #selector(refreshActiveInstallation),
                userInfo: nil,
                repeats: true
            )
        }
        
        Stats.incrementSuccessfulLaunchCount()
        Stats.evaluateSponsorMessageShouldBeDisplayed()
    }
    
    /**
     When the environment is not OK, present an alert to inform the user.
     */
    private func onEnvironmentFail() {
        DispatchQueue.main.async { [self] in
            
            BetterAlert()
                .withInformation(
                    title: "alert.cannot_start.title".localized,
                    subtitle: "alert.cannot_start.subtitle".localized,
                    description: "alert.cannot_start.description".localized
                )
                .withPrimary(text: "alert.cannot_start.retry".localized)
                .withSecondary(text: "alert.cannot_start.close".localized, action: { vc in
                    vc.close(with: .alertSecondButtonReturn)
                    exit(1)
                })
                .show()
            
            Task { await startup() }
        }
    }
}
