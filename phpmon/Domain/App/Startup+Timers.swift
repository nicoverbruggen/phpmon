//
//  Startup+Timers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/07/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import NVAlert

extension Startup {
    @MainActor static var startupTimer: Timer?
    @MainActor static var launchTime: Date?

    /** Returns a human-readable version to indicate how many seconds elapsed since boot. */
    @MainActor static var humanReadableSinceBootTime: String {
        return String(format: "%.2f", Date().timeIntervalSince(Self.launchTime!))
    }

    /** Starts the timeout timer that keeps track of how long the app takes to boot. */
    @MainActor func startStartupTimer() {
        Self.launchTime = Date()
        Self.startupTimer = Timer.scheduledTimer(
            timeInterval: Constants.SlowBootThresholdInterval, target: self,
            selector: #selector(startupTimeout), userInfo: nil, repeats: false
        )
    }

    /**
     Invalidates and stops the startup timer.
     This is only called if the slow boot threshold is not exceeded.
    */
    @MainActor static func invalidateTimeoutTimer() {
        if Self.startupTimer == nil {
            return
        }

        Log.info("PHP Monitor was quick; elapsed time: \(Self.humanReadableSinceBootTime) sec.")
        Self.startupTimer?.invalidate()
        Self.startupTimer = nil
    }

    /**
     Displays an alert for when the application startup process takes too long.
     */
    @MainActor @objc func startupTimeout() {
        Log.info("PHP Monitor was slow; elapsed time: \(Self.humanReadableSinceBootTime) sec.")

        // Invalidate the timer
        Self.startupTimer?.invalidate()
        Self.startupTimer = nil

        // Present an alert that lets the user know about the slow start
        NVAlert()
            .withInformation(
                title: "startup.timeout.title".localized,
                subtitle: "startup.timeout.subtitle".localized,
                description: "startup.timeout.description".localized
            )
            .withPrimary(text: "alert.cannot_start.close".localized, action: { vc in
                vc.close(with: .alertFirstButtonReturn)
                exit(1)
            })
            .withSecondary(text: "startup.timeout.ignore".localized, action: { vc in
                vc.close(with: .alertSecondButtonReturn)
            })
            .withTertiary(text: "", action: { _ in
                NSWorkspace.shared.open(URL(string: "https://github.com/nicoverbruggen/phpmon/issues/294")!)
            })
            .show(urgency: .urgentRequestAttention)
    }
}
