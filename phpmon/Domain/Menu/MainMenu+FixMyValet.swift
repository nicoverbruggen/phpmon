//
//  MainMenu+FixMyValet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/02/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import NVAlert

extension MainMenu {

    @MainActor @objc func fixMyValet() {
        let previousVersion = container.phpEnvs.phpInstall?.version.short

        if !App.shared.container.phpEnvs.availablePhpVersions.contains(PhpEnvironments.brewPhpAlias) {
            presentAlertForMissingFormula()
            return
        }

        if !NVAlert()
            .withInformation(
                title: "alert.fix_my_valet.title".localized,
                subtitle: "alert.fix_my_valet.info".localized(PhpEnvironments.brewPhpAlias)
            )
            .withPrimary(text: "alert.fix_my_valet.ok".localized)
            .withSecondary(text: "alert.fix_my_valet.cancel".localized)
            .didSelectPrimary() {
            Log.info("The user has chosen to abort Fix My Valet")
            return
        }

        Task { @MainActor in
            await Actions(container).fixMyValet()

            if previousVersion == PhpEnvironments.brewPhpAlias || previousVersion == nil {
                self.presentAlertForSameVersion()
            } else {
                self.presentAlertForDifferentVersion(version: previousVersion!)
            }
        }
    }

    @MainActor private func presentAlertForMissingFormula() {
        NVAlert()
            .withInformation(
                title: "alert.php_formula_missing.title".localized,
                subtitle: "alert.php_formula_missing.info".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    @MainActor private func presentAlertForSameVersion() {
        NVAlert()
            .withInformation(
                title: "alert.fix_my_valet_done.title".localized,
                subtitle: "alert.fix_my_valet_done.subtitle".localized,
                description: "alert.fix_my_valet_done.desc".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    @MainActor private func presentAlertForDifferentVersion(version: String) {
        NVAlert()
            .withInformation(
                title: "alert.fix_my_valet_done.title".localized,
                subtitle: "alert.fix_my_valet_done.subtitle".localized,
                description: "alert.fix_my_valet_done.desc".localized
            )
            .withPrimary(text: "alert.fix_my_valet_done.switch_back".localized(version), action: { alert in
                alert.close(with: .alertSecondButtonReturn)
                MainMenu.shared.switchToPhpVersion(version)
            })
            .withSecondary(text: "alert.fix_my_valet_done.stay".localized(PhpEnvironments.brewPhpAlias))
            .withTertiary(text: "", action: { _ in
                NSWorkspace.shared.open(Constants.Urls.FrequentlyAskedQuestions)
            })
            .show()
    }

}
