//
//  UpdateScheduler.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import os

actor UpdateScheduler {
    static let shared = UpdateScheduler()

    // `Timer` is not Sendable and must be scheduled *and* invalidated on the run loop
    // that installed it, so all Timer calls happen on the main actor. Guarding the
    // reference with `OSAllocatedUnfairLock` lets this actor hold on to it across
    // those isolations. The unchecked lock variants are required because `Timer` is
    // not Sendable; this stays safe because the timer is only ever created, read and
    // invalidated on the main actor (see `scheduleTimer`).
    private let currentTimer = OSAllocatedUnfairLock<Timer?>(uncheckedState: nil)

    private init() {}

    /**
     Start the automatic update checking process.
     This should be called once during app startup.
     */
    func startAutomaticUpdateChecking() async {
        await performUpdateCheck()
    }

    /**
     Perform an automatic update check and schedule the next one.
     */
    private func performUpdateCheck() async {
        // `Preferences` is nonisolated (lock-guarded leaf state), so the flag
        // can be read synchronously from this actor.
        let automaticChecksEnabled = Preferences.isEnabled(.automaticBackgroundUpdateCheck)

        guard automaticChecksEnabled else {
            Log.info("Automatic update checks disabled. Skipping check but maintaining schedule.")
            scheduleTimer()
            return
        }

        guard isNotThrottled() else {
            Log.info("Last check was too recent. Skipping check but maintaining schedule.")
            scheduleTimer()
            return
        }

        let result = await runUpdateCheck()

        switch result {
        case .success:
            // Reset failure count and record successful check
            UserDefaults.standard.removeObject(forKey: PersistentAppState.updateCheckFailureCount.rawValue)
            UserDefaults.standard.set(Date(), forKey: PersistentAppState.lastAutomaticUpdateCheck.rawValue)
            scheduleTimer()

        case .networkError, .parseError:
            // Handle failures with exponential backoff
            handleFailure(result: result)
        }
    }

    /**
     Runs the actual update check. `AppUpdater` is main-actor isolated, so both its
     construction and the check itself must happen on the main actor. The resulting
     `UpdateCheckResult` is returned to this actor.
     */
    @MainActor
    private func runUpdateCheck() async -> UpdateCheckResult {
        return await AppUpdater().checkForUpdates(userInitiated: false)
    }

    /**
     Handle update check failures with exponential backoff retry logic.
     */
    private func handleFailure(result: UpdateCheckResult) {
        let currentFailureCount = UserDefaults.standard.integer(
            forKey: PersistentAppState.updateCheckFailureCount.rawValue
        )
        let newFailureCount = currentFailureCount + 1

        UserDefaults.standard.set(newFailureCount, forKey: PersistentAppState.updateCheckFailureCount.rawValue)

        let retryInterval: TimeInterval
        if newFailureCount <= Constants.UpdateCheckRetryIntervals.count {
            // Use exponential backoff
            retryInterval = Constants.UpdateCheckRetryIntervals[newFailureCount - 1]
            Log.info("Update check failed (\(result)). Retry \(newFailureCount) in \(retryInterval)s.")
        } else {
            // Exceeded max retries, fall back to normal schedule and reset counter
            retryInterval = Constants.AutomaticUpdateCheckInterval
            UserDefaults.standard.removeObject(forKey: PersistentAppState.updateCheckFailureCount.rawValue)
            Log.info("Update check failed (\(result)). Max retries exceeded. Normal schedule in \(retryInterval)s.")
        }

        scheduleTimer(after: retryInterval)
    }

    /**
     Determine whether another automatic update check should occur based on the last check timestamp.
     Returns true if a check should happen, false otherwise.
     */
    private func isNotThrottled() -> Bool {
        let minimumTimeAgo = Date().addingTimeInterval(-Constants.MinimumUpdateCheckInterval)
        let lastCheckTime = UserDefaults.standard.object(
            forKey: PersistentAppState.lastAutomaticUpdateCheck.rawValue
        ) as? Date

        // If no previous check or last check was > minimum time frame, should check now
        return lastCheckTime == nil || lastCheckTime! < minimumTimeAgo
    }

    /**
     Schedule a timer to perform an update check after the specified interval.
     */
    private func scheduleTimer(after interval: TimeInterval = Constants.AutomaticUpdateCheckInterval) {
        // Timers must be scheduled on the main run loop (actors run on background threads)
        // and invalidated from the same thread, so both happen inside this main actor task.
        Task { @MainActor in
            // Invalidate any existing timer
            self.currentTimer.withLockUnchecked { $0 }?.invalidate()

            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                Task {
                    Log.info("Performing scheduled update check after \(interval)s.")
                    await self.performUpdateCheck()
                }
            }

            // Store the timer reference. `currentTimer` is a Sendable lock box (a
            // nonisolated `let`), so the actor can hold on to the reference even though
            // the timer itself only ever lives on the main run loop.
            self.currentTimer.withLockUnchecked { $0 = timer }
        }

        Log.info("Next update check scheduled in \(interval)s.")
    }
}
