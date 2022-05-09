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
        // Determine install method
        Log.info(HomebrewDiagnostics.customCaskInstalled
            ? "The app has probably been installed via Homebrew Cask."
            : "The app has probably been installed directly."
        )

        // Attempt to find out more info about Valet
        if Valet.shared.version != nil {
            Log.info("PHP Monitor has extracted the version number of Valet: \(Valet.shared.version!)")
        }

        // Validate the version (this will enforce which versions of PHP are supported)
        Valet.shared.validateVersion()

        // Actually detect the PHP versions
        PhpEnv.detectPhpVersions()

        // Check for an alias conflict
        if HomebrewDiagnostics.hasAliasConflict() {
            HomebrewDiagnostics.presentAlertAboutConflict()
        }

        updatePhpVersionInStatusBar()

        Log.info("Determining broken PHP-FPM...")
        // Attempt to find out if PHP-FPM is broken
        let installation = PhpEnv.phpInstall
        installation.notifyAboutBrokenPhpFpm()

        // Set up the config watchers on launch
        // (these are automatically updated via delegate methods if the user switches)
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

        // Preload sites
        Valet.shared.startPreloadingSites()

        // A non-default TLD is not officially supported since Valet 3.2.x
        Valet.notifyAboutUnsupportedTLD()

        NotificationCenter.default.post(name: Events.ServicesUpdated, object: nil)

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

        Updater.checkForUpdates()

        Log.info("PHP Monitor is ready to serve!")
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
