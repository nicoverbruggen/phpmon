//
//  MainMenu+PhpSwitcherDelegate.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension MainMenu {

    // MARK: - PhpSwitcherDelegate

    nonisolated func switcherDidStartSwitching(to version: String) {}

    nonisolated func switcherDidCompleteSwitch(to version: String) {
        // Mark as no longer busy
        PhpEnv.shared.isBusy = false

        Task { // Things to do after reloading domain list data
            if Valet.installed {
                await self.reloadDomainListData()
            }

            // Perform UI updates on main thread
            Task { @MainActor [self] in
                updatePhpVersionInStatusBar()
                rebuild()

                if !PhpEnv.shared.validate(version) {
                    self.suggestFixMyValet(failed: version)
                    return
                }

                // Run composer updates
                if Preferences.isEnabled(.autoComposerGlobalUpdateAfterSwitch) {
                    ComposerWindow().updateGlobalDependencies(
                        notify: false,
                        completion: { _ in
                            self.notifyAboutVersionChange(to: version)
                        }
                    )
                } else {
                    self.notifyAboutVersionChange(to: version)
                }

                // Check if Valet still works correctly
                self.checkForPlatformIssues()

                // Update stats
                Stats.incrementSuccessfulSwitchCount()
                Stats.evaluateSponsorMessageShouldBeDisplayed()
            }
        }
    }

    @MainActor private func checkForPlatformIssues() {
        Task { // Asynchronously check for platform issues
            if await Valet.shared.hasPlatformIssues() {
                Log.info("Composer platform issue(s) detected.")
                self.suggestFixMyComposer()
            }
        }
    }

    @MainActor private func suggestFixMyValet(failed version: String) {
        let outcome = BetterAlert()
            .withInformation(
                title: "alert.php_switch_failed.title".localized(version),
                subtitle: "alert.php_switch_failed.info".localized(version),
                description: "alert.php_switch_failed.desc".localized()
            )
            .withPrimary(text: "alert.php_switch_failed.confirm".localized)
            .withSecondary(text: "alert.php_switch_failed.cancel".localized)
            .didSelectPrimary()
        if outcome {
            MainMenu.shared.fixMyValet()
        }
    }

    @MainActor private func suggestFixMyComposer() {
        BetterAlert().withInformation(
            title: "alert.global_composer_platform_issues.title".localized,
            subtitle: "alert.global_composer_platform_issues.subtitle".localized,
            description: "alert.global_composer_platform_issues.desc".localized
        )
        .withPrimary(text: "alert.global_composer_platform_issues.buttons.update".localized, action: { alert in
            alert.close(with: .OK)
            Log.info("The user has chosen to update global dependencies.")
            ComposerWindow().updateGlobalDependencies(
                notify: true,
                completion: { success in
                    Log.info("Dependencies updated successfully: \(success)")
                    Log.info("Re-checking for platform issue(s)...")
                    self.checkForPlatformIssues()
                }
            )
        })
        .withSecondary(text: "", action: nil)
        .withTertiary(text: "alert.global_composer_platform_issues.buttons.quit".localized, action: { alert in
            alert.close(with: .OK)
            self.terminateApp()
        })
        .show()
    }

    private func reloadDomainListData() async {
        if let window = App.shared.domainListWindowController {
            await window.contentVC.reloadDomains()
        } else {
            await Valet.shared.reloadSites()
        }
    }

    @MainActor private func notifyAboutVersionChange(to version: String) {
        LocalNotification.send(
            title: String(format: "notification.version_changed_title".localized, version),
            subtitle: String(format: "notification.version_changed_desc".localized, version),
            preference: .notifyAboutVersionChange
        )

        guard PhpEnv.phpInstall != nil else {
            Log.err("Cannot notify about version change if PHP is unlinked")
            return
        }

        guard Valet.installed == true else {
            Log.info("Skipping check for broken PHP-FPM version, Valet is not installed")
            return
        }

        Task {
            await Valet.shared.notifyAboutBrokenPhpFpm()
        }
    }
}
