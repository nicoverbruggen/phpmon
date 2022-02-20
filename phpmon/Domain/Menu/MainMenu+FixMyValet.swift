//
//  MainMenu+FixMyValet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension MainMenu {
    
    @objc func fixMyValet() {
        let previousVersion = PhpEnv.phpInstall.version.short
        
        if !PhpEnv.shared.availablePhpVersions.contains(PhpEnv.brewPhpVersion) {
            presentAlertForMissingFormula()
            return
        }
        
        if !BetterAlert()
            .withInformation(
                title: "alert.fix_my_valet.title".localized,
                subtitle: "alert.fix_my_valet.info".localized(PhpEnv.brewPhpVersion)
            )
            .withPrimary(text: "alert.fix_my_valet.ok".localized)
            .withSecondary(text: "alert.fix_my_valet.cancel".localized)
            .didSelectPrimary()
        {
            Log.info("The user has chosen to abort Fix My Valet")
            return
        }
        
        asyncExecution {
            Actions.fixMyValet()
        } success: {
            if previousVersion == PhpEnv.brewPhpVersion {
                self.presentAlertForSameVersion()
            } else {
                self.presentAlertForDifferentVersion(version: previousVersion)
            }
        }
    }
    
    private func presentAlertForMissingFormula() {
        BetterAlert()
            .withInformation(
                title: "alert.php_formula_missing.title".localized,
                subtitle: "alert.php_formula_missing.info".localized
            )
            .withPrimary(text: "OK")
            .show()
    }
    
    private func presentAlertForSameVersion() {
        BetterAlert()
            .withInformation(
                title: "alert.fix_my_valet_done.title".localized,
                subtitle: "alert.fix_my_valet_done.subtitle".localized,
                description: "alert.fix_my_valet_done.desc".localized
            )
            .withPrimary(text: "OK")
            .show()
    }
    
    private func presentAlertForDifferentVersion(version: String) {
        BetterAlert()
            .withInformation(
                title: "alert.fix_my_valet_done.title".localized,
                subtitle: "alert.fix_my_valet_done.subtitle".localized,
                description: "alert.fix_my_valet_done.desc".localized
            )
            .withPrimary(text: "alert.fix_my_valet_done.stay".localized(PhpEnv.brewPhpVersion))
            .withSecondary(text: "alert.fix_my_valet_done.switch_back".localized(version), action: { alert in
                alert.close(with: .alertSecondButtonReturn)
                MainMenu.shared.switchToPhpVersion(version)
            })
            .show()
    }
    
}
