//
//  Startup+Timers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/07/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Startup {
    @MainActor static var startupTimer: Timer?
    @MainActor static var launchTime: Date?

    @MainActor func startTimeoutTimer() {
        Self.launchTime = Date()
        Self.startupTimer = Timer.scheduledTimer(
            timeInterval: Constants.SlowBootThresholdInterval, target: self,
            selector: #selector(startupTimeout), userInfo: nil, repeats: false
        )
    }

    @MainActor static func invalidateTimeoutTimer() {
        let elapsedTime = Date().timeIntervalSince(Self.launchTime!)
        let printableTime = String(format: "%.2f", elapsedTime)

        Log.info("PHP Monitor launched quickly enough!")
        Log.info("PHP Monitor boot time: \(printableTime) sec")
        Self.startupTimer?.invalidate()
        Self.startupTimer = nil
    }
}
