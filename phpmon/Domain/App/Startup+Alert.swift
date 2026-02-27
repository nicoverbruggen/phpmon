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
        /** The automatic fix ran and succeeded. Continue to the next check. */
        case shouldContinue

        /** No automatic fix was requested, show alert and require retry of all startup checks. */
        case shouldRetryStartup
    }

    /**
     Displays an alert for a particular check. For checks that require an app restart,
     a simple NVAlert is shown with a quit button. For all other checks, the new
     StartupAlertWindowController is used to show the enhanced startup alert.
     */
    @MainActor internal func showAlert(for check: EnvironmentCheck) async -> EnvironmentAlertOutcome {
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

        // Create and show the enhanced startup alert window
        let controller = StartupAlertWindowController.create(for: check)
        return await controller.showModal()
    }
}
