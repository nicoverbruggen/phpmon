//
//  AutomaticUpdateService.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/09/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor UpdateScheduler {
    static let shared = UpdateScheduler()

    private var currentTimer: Timer?

    private init() {}

    /**
     Start the automatic update checking process. This should be called once during app startup.
     */
    func startAutomaticUpdateChecking() async {
        await performUpdateCheck()
    }

    /**
     Perform an automatic update check and schedule the next one.
     */
    private func performUpdateCheck() async {
        guard isNotThrottled() else {
            // If we are throttled, just schedule a regular check 24 hours from now.
            scheduleTimer()
            return
        }

        let result = await AppUpdater().checkForUpdates(userInitiated: false)

        switch result {
        case .success:
            // Reset failure count and record successful check
            UserDefaults.standard.removeObject(forKey: PersistentAppState.updateCheckFailureCount.rawValue)
            UserDefaults.standard.set(Date(), forKey: PersistentAppState.lastAutomaticUpdateCheck.rawValue)
            scheduleTimer()
            Log.info("Update check succeeded. Next check in \(Constants.AutomaticUpdateCheckInterval)s.")

        case .disabled:
            // User disabled automatic checks, don't schedule another
            Log.info("Automatic update checks disabled. No further checks scheduled.")

        case .networkError, .parseError:
            // Handle failures with exponential backoff
            handleFailure(result: result)
        }
    }

    /**
     Handle update check failures with exponential backoff retry logic.
     */
    private func handleFailure(result: UpdateCheckResult) {
        let currentFailureCount = UserDefaults.standard.integer(forKey: PersistentAppState.updateCheckFailureCount.rawValue)
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
        guard Preferences.isEnabled(.automaticBackgroundUpdateCheck) else {
            return false
        }

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
        // Invalidate any existing timer
        currentTimer?.invalidate()

        // Ensure timer is scheduled on main run loop since actors run on background threads
        Task { @MainActor in
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                Task {
                    Log.info("Performing scheduled update check after \(interval)s.")
                    await self.performUpdateCheck()
                }
            }

            // Store timer reference back in actor
            await self.setCurrentTimer(timer)
        }

        Log.info("Next update check scheduled in \(interval)s.")
    }

    /**
     Set the current timer reference. Used to store timer from main thread back to actor.
     */
    private func setCurrentTimer(_ timer: Timer) {
        currentTimer = timer
    }
}
