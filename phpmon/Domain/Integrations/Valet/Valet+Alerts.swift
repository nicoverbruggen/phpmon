//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert

extension Valet {

    /**
     Notify the user about a non-default TLD being set.
     */
    public func notifyAboutUnsupportedTLD() {
        if Valet.shared.config.tld != "test" && Preferences.isEnabled(.warnAboutNonStandardTLD) {
            Task { @MainActor in
                NVAlert().withInformation(
                    title: "alert.warnings.tld_issue.title".localized,
                    subtitle: "alert.warnings.tld_issue.subtitle".localized,
                    description: "alert.warnings.tld_issue.description".localized
                )
                .withPrimary(text: "generic.ok".localized)
                .withTertiary(text: "alert.do_not_tell_again".localized, action: { alert in
                    Preferences.update(.warnAboutNonStandardTLD, value: false)
                    alert.close(with: .alertThirdButtonReturn)
                })
                .show(urgency: .urgentRequestAttention)
            }
        }
    }

    public func notifyAboutOutdatedValetVersion(_ version: VersionNumber) {
        Task { @MainActor in
            NVAlert()
                .withInformation(
                    title: "alert.min_valet_version.title".localized,
                    subtitle: "alert.min_valet_version.info".localized(
                        version.text,
                        Constants.MinimumRecommendedValetVersion
                    )
                )
                .withPrimary(text: "generic.ok".localized)
                .show(urgency: .urgentRequestAttention)
        }
    }

    /**
     It is always possible that the system configuration for PHP-FPM has not been set up for Valet.
     This can occur when a user manually installs a new PHP version, but does not run `valet install`.
     In that case, we should alert the user!
     
     - Important: The underlying check is `checkPhpFpmStatus`, which can be run multiple times.
     This method actively presents a modal if said checks fails, so don't call this method too many times.
     */
    public func notifyAboutBrokenPhpFpm() async {
        if await Valet.shared.phpFpmConfigurationValid() {
            return
        }

        Task { @MainActor in
            NVAlert()
                .withInformation(
                    title: "alert.php_fpm_broken.title".localized,
                    subtitle: "alert.php_fpm_broken.info".localized,
                    description: "alert.php_fpm_broken.description".localized
                )
                .withPrimary(text: "generic.ok".localized)
                .show(urgency: .urgentRequestAttention)
        }
    }

}
