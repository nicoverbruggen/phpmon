//
//  MainMenu+PhpSwitcherDelegate.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension MainMenu {

    // MARK: - PhpSwitcherDelegate

    func switcherDidStartSwitching(to version: String) {}

    func switcherDidCompleteSwitch(to version: String) {
        // Mark as no longer busy
        PhpEnv.shared.isBusy = false

        // Reload the site list
        self.reloadDomainListData()

        // Perform UI updates on main thread
        DispatchQueue.main.async { [self] in
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

            // Update stats
            Stats.incrementSuccessfulSwitchCount()
            Stats.evaluateSponsorMessageShouldBeDisplayed()
        }
    }

    private func suggestFixMyValet(failed version: String) {
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

    private func reloadDomainListData() {
        if let window = App.shared.domainListWindowController {
            DispatchQueue.main.async {
                window.contentVC.reloadDomains()
            }
        } else {
            Valet.shared.reloadSites()
        }
    }

    private func notifyAboutVersionChange(to version: String) {
        LocalNotification.send(
            title: String(format: "notification.version_changed_title".localized, version),
            subtitle: String(format: "notification.version_changed_desc".localized, version),
            preference: .notifyAboutVersionChange
        )

        PhpEnv.phpInstall.notifyAboutBrokenPhpFpm()
    }
}
