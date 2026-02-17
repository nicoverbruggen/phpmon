//
//  Startup+Fixes.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import NVAlert

extension Startup {
    /**
     The potential outcome of an environment check failure alert.
     */
    enum EnvironmentAlertOutcome {
        /** The automatic fix was requested, will try and continue if it worked. */
        case shouldRunFix

        /** No automatic fix was requested, show alert and require retry of all startup checks. */
        case shouldRetryStartup
    }

    /**
     Displays an alert for a particular check. There are two types of alerts:
     - ones that require an app restart, which prompt the user to exit the app
     - ones that allow the app to continue, which allow the user to retry
     */
    @MainActor internal func showAlert(for check: EnvironmentCheck) -> EnvironmentAlertOutcome {
        // Ensure that the timeout does not fire until we restart
        Self.startupTimer?.invalidate()

        if check.requiresAppRestart {
            NVAlert()
                .withInformation(
                    title: check.titleText,
                    subtitle: check.subtitleText,
                    description: check.descriptionText
                )
                .withPrimary(text: check.buttonText, action: { _ in
                    exit(1)
                }).show(urgency: .bringToFront)
        }

        // Verify if an automatic fix is available
        let hasAutomaticFix = check.fixCommand != nil

        // Present an alert with one or two buttons (depending on fix)
        let outcome = NVAlert()
            .withInformation(
                title: check.titleText,
                subtitle: check.subtitleText,
                description: check.descriptionText
            )
            .withPrimary(text: hasAutomaticFix ? "startup.fix_for_me".localized : "startup.fix_manually".localized)
            .withSecondary(if: hasAutomaticFix, text: "startup.fix_manually".localized)
            .withTertiary(if: hasAutomaticFix, text: "", action: { _ in
                NSWorkspace.shared.open(Constants.Urls.FrequentlyAskedQuestions)
            })
            .runModal(urgency: .bringToFront)

        // If there's an automatic fix and we chose to fix it, return outcome
        if hasAutomaticFix && outcome == .alertFirstButtonReturn {
            return .shouldRunFix
        }

        // In any other situation, we will require a retry of the startup
        return .shouldRetryStartup
    }
}
