//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import NVAlert

// Startup is the app-launch orchestration: it drives the menu, status item and
// windows, so it lives on the main actor. The async work it kicks off (shell I/O,
// Homebrew/Valet queries) hops off-main on the nonisolated/actor services it calls.
@MainActor
class Startup {
    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     If this method returns false, there was a failed check and an alert was displayed.
     If this method returns true, then all checks succeeded and the app can continue.
     */
    func checkEnvironment() async -> Bool {
        // Set up the startup timeout timer. We are already on the main actor
        // (Startup is @MainActor), so no explicit hop is required.
        startStartupTimer()

        for group in self.groups {
            if group.condition() {
                Log.info("Now running \(group.checks.count) \(group.name) checks!")
                for check in group.checks {
                    let start = Measurement()
                    if await check.succeeds() {
                        Log.info("[PASS] \(check.name) (\(start.milliseconds) ms)")
                        continue // continue to the next check!
                    }

                    // If we get here, something's gone wrong and the check has failed...
                    Log.info("[FAIL] \(check.name) (\(start.milliseconds) ms)")

                    // We will present the user with an option (potentially)
                    let outcome = await showAlert(for: check)

                    // The fix ran and succeeded — continue to the next check
                    if outcome == .shouldContinue {
                        continue
                    }

                    // No fix requested or fix failed — requires full restart
                    return false
                }
            } else {
                Log.info("Skipping \(group.name) checks!")
            }
        }

        // If we get here, nothing has gone wrong. That's what we want!
        Log.info("PHP Monitor has determined the application has successfully passed all checks.")

        Log.separator(as: .info)
        return true
    }
}
