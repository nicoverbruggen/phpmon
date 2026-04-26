//
//  Startup+Launch.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import NVAlert

extension Startup {
    /**
     Kick off the startup of the rendering of the main menu.
     */
    static func check(_ container: Container) async {
        // Create a new instance of Startup w/ the container
        let startup = Startup(container)

        // Perform the startup checks
        await startup.check()
    }

    /**
     Perform all checks and execute pass or fail results.
     */
    private func check() async {
        // Determine if the initial onboarding flow is required
        // This will trigger when the environment is minimal
        // (i.e. missing core dependencies)
        await checkOnboarding()

        // Next up, validate the environment is healthy
        // This is required for phpmon to function right
        if await self.checkEnvironment() {
            await self.onEnvironmentPass()
        } else {
            await self.onEnvironmentFail()
        }
    }

    private func checkOnboarding() async {
        let disposition = await onboardingDisposition()
        Log.info("Determined onboarding flow: \(disposition)")

        if disposition == .wizard {
            // Show the wizard and we'll await the result of the wizard
            let outcome = await showOnboardingWizard()
            Log.info("Outcome of onboarding: \(outcome)")
        }
    }

    /**
     When the environment is all clear and the app can run, let's go.
     */
    @MainActor
    private func onEnvironmentPass() async {
        // Load additional preferences
        await container.preferences.loadCustomPreferences()

        // Determine what the `php` formula is aliased to (again)
        await container.phpEnvs.determinePhpAlias()

        // Make sure that broken symlinks are removed ASAP
        await BrewDiagnostics.shared.checkForOutdatedPhpInstallationSymlinks()

        // Put some useful diagnostics information in log
        BrewDiagnostics.shared.logBootInformation()

        // Attempt to find out more info about Valet
        if Valet.shared.version != nil {
            Log.info("PHP Monitor has extracted the version number of Valet: \(Valet.shared.version!.text)")

            // Validate the version (this will enforce which versions of PHP are supported)
            Valet.shared.validateVersion()
        }

        // Validate the Homebrew version (determines install/upgrade functionality)
        await Brew.shared.determineVersion()

        // Verify third party taps (will display as warning)
        await BrewDiagnostics.shared.verifyThirdPartyTaps()

        // Actually detect the PHP versions
        await container.phpEnvs.reloadPhpVersions()

        // Set up the filesystem watcher for the Homebrew binaries
        await HomebrewWatchManager.prepare()

        // Set up the config watchers on launch (updated automatically when switching)
        await ConfigWatchManager.handleWatcher()

        // Detect built-in and custom applications
        await App.shared.detectApplications()

        // Load the rollback preset
        PresetHelper.loadRollbackPresetFromFile()

        // Load the global hotkey
        App.shared.loadGlobalHotkey()

        // Set up menu items
        AppDelegate.instance.configureMenuItems(standalone: !Valet.installed)

        if Valet.installed {
            // Preload all sites
            await Valet.shared.startPreloadingSites()

            // After preloading sites, check for PHP-FPM pool conflicts
            await BrewDiagnostics.shared.checkForValetMisconfiguration()

            // Check if PHP-FPM is broken (should be fixed automatically if phpmon >= 6.0)
            await Valet.shared.notifyAboutBrokenPhpFpm()

            // A non-default TLD is not officially supported since Valet 3.2.x
            Valet.shared.notifyAboutUnsupportedTLD()

            // Determine which services are running
            await ServicesManager.shared.reloadServicesStatus()

            // Find out which services are active
            Log.info("The services manager knows about \(ServicesManager.shared.services.count) services.")
        }

        // Keep track of which PHP versions are currently about to release
        Log.info("Experimental PHP versions are: \(Constants.ExperimentalPhpVersions)")

        // Internals are ready!
        container.phpEnvs.isBusy = false

        // Avoid showing the "startup timeout" alert
        Startup.invalidateTimeoutTimer()

        // On the very first successful boot, ask for notification permissions only
        // after onboarding and environment validation have both completed.
        if Stats.successfulLaunchCount == 0 {
            NotificationPermission.request()
        }

        // Check if we upgraded from a previous version
        AppUpdater.checkIfUpdateWasPerformed()

        // Mark app as having successfully booted passing all checks
        Startup.hasFinishedBooting = true
        Log.info("PHP Monitor is ready to serve!")

        // Process the last URL that arrived during startup
        if let url = App.shared.deferredURL {
            AppDelegate.instance.handleURLs([url])
            App.shared.deferredURL = nil
        }

        // Enable the main menu item
        MainMenu.shared.statusItem.button?.isEnabled = true

        // PHP Doctor warnings can inspect shell and PATH state, so defer them
        // until after startup has fully completed and the menu is interactive.
        container.warningManager.evaluateWarnings()

        // Post-launch stats and update check, but only if not running tests
        await performPostLaunchActions()
    }

    /**
     Performs a set of post-launch actions, like incrementing stats and checking for updates.
     (This code is skipped when running SwiftUI previews.)
     */
    private func performPostLaunchActions() async {
        if isRunningSwiftUIPreview {
            return
        }

        Stats.incrementSuccessfulLaunchCount()
        Stats.evaluateSponsorMessageShouldBeDisplayed()

        if Stats.successfulLaunchCount == 1 {
            Log.info("Should present the welcome screen!")
            Task { @MainActor in
                WelcomeTourWindowController.show()
            }
        } else {
            // Check for updates
            await UpdateScheduler.shared.startAutomaticUpdateChecking()

            // Check if the linked version has changed between launches of phpmon
            await PhpGuard().compareToLastGlobalVersion()

            // Check if Valet has updates, but only if the driver display is enabled
            if Preferences.isEnabled(.displayDriver) {
                await Valet.shared.checkForUpdates()
            }
        }
    }

    /**
     When the environment is not OK, present an alert to inform the user.
     */
    @MainActor
    private func onEnvironmentFail() async {
        NVAlert()
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
            .show(urgency: .bringToFront)

        await self.check()
    }
}
