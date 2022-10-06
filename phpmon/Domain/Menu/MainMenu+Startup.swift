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

        await App.shared.environment.process()

        if await Startup().checkEnvironment() {
            await self.onEnvironmentPass()
        } else {
            await self.onEnvironmentFail()
        }
    }

    /**
     When the environment is all clear and the app can run, let's go.
     */
    private func onEnvironmentPass() async {
        // Determine what the `php` formula is aliased to
        await PhpEnv.shared.determinePhpAlias()

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
        await PhpEnv.detectPhpVersions()

        // Check for an alias conflict
        HomebrewDiagnostics.checkForCaskConflict()

        // Update the icon
        updatePhpVersionInStatusBar()

        // Attempt to find out if PHP-FPM is broken
        Log.info("Determining broken PHP-FPM...")
        let installation = PhpEnv.phpInstall
        installation.notifyAboutBrokenPhpFpm()

        // Check for other problems
        WarningManager.shared.evaluateWarnings()

        // Set up the config watchers on launch (updated automatically when switching)
        Log.info("Setting up watchers...")
        App.shared.handlePhpConfigWatcher()

        // Detect built-in and custom applications
        detectApplications()

        // Load the rollback preset
        PresetHelper.loadRollbackPresetFromFile()

        // Load the global hotkey
        App.shared.loadGlobalHotkey()

        // Preload sites
        await Valet.shared.startPreloadingSites()

        // After preloading sites, check for PHP-FPM pool conflicts
        HomebrewDiagnostics.checkForPhpFpmPoolConflicts()

        // A non-default TLD is not officially supported since Valet 3.2.x
        Valet.notifyAboutUnsupportedTLD()

        // Find out which services are active
        await ServicesManager.loadHomebrewServices()

        // Start the background refresh timer
        startSharedTimer()

        // Update the stats
        Stats.incrementSuccessfulLaunchCount()

        #if SPONSOR
            Log.info("Sponsor encouragement messages are omitted in SE builds.")
        #else
            Stats.evaluateSponsorMessageShouldBeDisplayed()
        #endif

        // Present first launch screen if needed
        if Stats.successfulLaunchCount == 0 && !isRunningSwiftUIPreview {
            Log.info("Should present the first launch screen!")
            DispatchQueue.main.async {
                OnboardingWindowController.show()
            }
        }

        // Check for updates
        await AppUpdateChecker.checkIfNewerVersionIsAvailable()

        // We are ready!
        Log.info("PHP Monitor is ready to serve!")
    }

    /**
     When the environment is not OK, present an alert to inform the user.
     */
    private func onEnvironmentFail() async {
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

    /**
     Schedule a request to fetch the PHP version every 60 seconds.
     */
    private func startSharedTimer() {
        DispatchQueue.main.async { [self] in
            App.shared.timer = Timer.scheduledTimer(
                timeInterval: 60,
                target: self,
                selector: #selector(refreshActiveInstallation),
                userInfo: nil,
                repeats: true
            )
        }
    }

    /**
     Detect which applications are installed that can be used to open a domain's source directory.
     */
    private func detectApplications() {
        Task {
            Log.info("Detecting applications...")

            App.shared.detectedApplications = await Application.detectPresetApplications()

            let customApps = Preferences.custom.scanApps?.map { appName in
                return Application(appName, .user_supplied)
            } ?? []

            var detectedCustomApps: [Application] = []

            for app in customApps where await app.isInstalled() {
                detectedCustomApps.append(app)
            }

            App.shared.detectedApplications
                .append(contentsOf: detectedCustomApps)

            let appNames = App.shared.detectedApplications.map { app in
                return app.name
            }

            Log.info("Detected applications: \(appNames)")
        }
    }
}
