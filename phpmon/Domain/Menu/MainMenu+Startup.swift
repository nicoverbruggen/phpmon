//
//  MainMenu+Startup.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/01/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension MainMenu {
    /**
     Kick off the startup of the rendering of the main menu.
     */
    func startup() async {
        // Start with the icon
        Task { @MainActor in
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

        // Initialize preferences
        _ = Preferences.shared

        // Determine install method
        Log.info(HomebrewDiagnostics.customCaskInstalled
            ? "[BREW] The app has probably been installed via Homebrew Cask."
            : "[BREW] The app has probably been installed directly."
        )

        Log.info(HomebrewDiagnostics.usesNginxFullFormula
             ? "[BREW] The app will be using the `nginx-full` formula."
             : "[BREW] The app will be using the `nginx` formula."
        )

        // Attempt to find out more info about Valet
        if Valet.shared.version != nil {
            Log.info("PHP Monitor has extracted the version number of Valet: \(Valet.shared.version!.text)")
        }

        // Validate the version (this will enforce which versions of PHP are supported)
        Valet.shared.validateVersion()

        // Actually detect the PHP versions
        await PhpEnv.detectPhpVersions()

        // Check for an alias conflict
        await HomebrewDiagnostics.checkForCaskConflict()

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
        await detectApplications()

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
        Log.info("The services manager knows about \(ServicesManager.shared.services.count) services.")

        // Start the background refresh timer
        startSharedTimer()

        if !isRunningSwiftUIPreview {
            Stats.incrementSuccessfulLaunchCount()
            Stats.evaluateSponsorMessageShouldBeDisplayed()

            if Stats.successfulLaunchCount == 1 {
                Log.info("Should present the first launch screen!")
                Task { @MainActor in
                    OnboardingWindowController.show()
                }
            } else {
                await AppUpdater().checkForUpdates(interactive: false)
            }
        }

        // Check if the linked version has changed between launches of phpmon
        Stats.evaluateLastLinkedPhpVersion()

        // Check if an update was performed earlier
        AppUpdater.checkIfUpdateWasPerformed()

        // We are ready!
        Log.info("PHP Monitor is ready to serve!")
    }

    /**
     When the environment is not OK, present an alert to inform the user.
     */
    private func onEnvironmentFail() async {
        Task { @MainActor [self] in
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

            Task { // An issue occurred, fire startup checks again after dismissal
                await startup()
            }
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
    private func detectApplications() async {
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
