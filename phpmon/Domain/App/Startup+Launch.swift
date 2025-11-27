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
        if await self.checkEnvironment() {
            await self.onEnvironmentPass()
        } else {
            await self.onEnvironmentFail()
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
        App.shared.prepareHomebrewWatchers()

        // Check for other problems
        container.warningManager.evaluateWarnings()

        // Set up the config watchers on launch (updated automatically when switching)
        App.shared.handlePhpConfigWatcher()

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
        }

        // Keep track of which PHP versions are currently about to release
        Log.info("Experimental PHP versions are: \(Constants.ExperimentalPhpVersions)")

        // Find out which services are active
        Log.info("The services manager knows about \(ServicesManager.shared.services.count) services.")

        // We are ready!
        container.phpEnvs.isBusy = false

        // Finally!
        Log.info("PHP Monitor is ready to serve!")

        // Avoid showing the "startup timeout" alert
        Startup.invalidateTimeoutTimer()

        // Check if we upgraded from a previous version
        AppUpdater.checkIfUpdateWasPerformed()

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
            Log.info("Should present the first launch screen!")
            Task { @MainActor in
                OnboardingWindowController.show()
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
