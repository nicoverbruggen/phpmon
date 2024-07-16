//
//  PhpGuard.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert

class PhpGuard {

    var currentVersion: String?

    init() {
        guard let linked = PhpEnvironments.phpInstall else {
            Log.warn("PHP Guard is unable to determine the current PHP version!")
            return
        }

        currentVersion = linked.version.short
        Log.info("The currently linked version of PHP is: \(linked.version.short).")
    }

    public func compareToLastGlobalVersion() {
        guard let currentVersion else {
            return
        }

        let previousVersion = Stats.lastGlobalPhpVersion

        if previousVersion == "" {
            Stats.persistCurrentGlobalPhpVersion(version: currentVersion)
            return Log.warn("PHP Guard is saving the currently linked PHP version (first time only).")
        }
        Log.info("Previously, the globally linked PHP version was: \(previousVersion).")

        if previousVersion == currentVersion {
            return Log.info("PHP Guard did not notice any changes in the linked PHP version.")
        }

        // At this point, the version is *not* a match
        Log.info("PHP Guard noticed a different PHP version. An alert will be displayed!")

        Task { @MainActor in
            NVAlert()
                .withInformation(
                    title: "startup.version_mismatch.title".localized,
                    subtitle: "startup.version_mismatch.subtitle".localized(
                        currentVersion,
                        previousVersion
                    ),
                    description: "startup.version_mismatch.desc".localized()
                )
                .withPrimary(text: "startup.version_mismatch.button_switch_back".localized(
                    previousVersion
                ), action: { alert in
                    alert.close(with: .OK)
                    Task { MainMenu.shared.switchToAnyPhpVersion(previousVersion) }
                })
                .withTertiary(text: "startup.version_mismatch.button_stay".localized(
                    currentVersion
                ), action: { alert in
                    Stats.persistCurrentGlobalPhpVersion(version: currentVersion)
                    alert.close(with: .OK)
                })
                .show()
        }
    }
}
