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
        // Update the PHP version
        PhpEnv.shared.currentInstall = ActivePhpInstallation()
        
        // Ensure the config watcher gets reloaded
        App.shared.handlePhpConfigWatcher()
        
        // Mark as no longer busy
        PhpEnv.shared.isBusy = false
        
        // Reload the site list
        self.reloadSiteListData()
        
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
                self.updateGlobalDependencies(notify: false, completion: { _ in
                    self.notifyAboutVersionChange(to: version)
                })
            } else {
                self.notifyAboutVersionChange(to: version)
            }
            
            // Update stats
            Stats.incrementSuccessfulSwitchCount()
            Stats.evaluateSponsorMessageShouldBeDisplayed()
        }
    }
    
    private func suggestFixMyValet(failed version: String) {
        let outcome = Alert.present(
            messageText: "alert.php_switch_failed.title".localized(version),
            informativeText: "alert.php_switch_failed.info".localized(version),
            buttonTitle: "alert.php_switch_failed.confirm".localized,
            secondButtonTitle: "alert.php_switch_failed.cancel".localized, style: .informational)
        if outcome {
            MainMenu.shared.fixMyValet()
        }
    }
    
    private func reloadSiteListData() {
        if let window = App.shared.siteListWindowController {
            DispatchQueue.main.async {
                window.contentVC.reloadSites()
            }
        } else {
            Valet.shared.reloadSites()
        }
    }
    
    private func notifyAboutVersionChange(to version: String) {
        LocalNotification.send(
            title: String(format: "notification.version_changed_title".localized, version),
            subtitle: String(format: "notification.version_changed_desc".localized, version)
        )
        
        PhpEnv.phpInstall.notifyAboutBrokenPhpFpm()
    }
}
