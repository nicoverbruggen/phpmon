//
//  Stats.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/01/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import NVAlert

class Stats {

    // MARK: - Backing storage

    /**
     In-memory stats, used when a testable (fake) container is active: UI test
     runs must never pollute the real, persisted stats (launch counts, etc.),
     which are shared with any other copy of the app on this machine. Seeded
     with a testable configuration's `internalStatsOverrides`.
     */
    private static var inMemoryStats: [String: Any] = [:]

    private static var usesInMemoryStats: Bool {
        return App.shared.container.filesystem is TestableFileSystem
    }

    /** Seeds the in-memory stats from a testable configuration. */
    static func applyTestOverrides(_ overrides: [String: Int]) {
        overrides.forEach { inMemoryStats[$0.key] = $0.value }
    }

    private static func readInteger(_ key: String) -> Int {
        if usesInMemoryStats {
            return inMemoryStats[key] as? Int ?? 0
        }

        return UserDefaults.standard.integer(forKey: key)
    }

    private static func readBool(_ key: String) -> Bool {
        if usesInMemoryStats {
            return inMemoryStats[key] as? Bool ?? false
        }

        return UserDefaults.standard.bool(forKey: key)
    }

    private static func readString(_ key: String) -> String? {
        if usesInMemoryStats {
            return inMemoryStats[key] as? String
        }

        return UserDefaults.standard.string(forKey: key)
    }

    private static func write(_ value: Any?, forKey key: String) {
        if usesInMemoryStats {
            inMemoryStats[key] = value
            return
        }

        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    /**
     Keep track of how many times the app has been successfully launched.
     
     This is used to determine whether it is time to show the sponsor
     encouragement alert, but I'd like to include this stat somewhere
     else as well.
     */
    public static var successfulLaunchCount: Int {
        readInteger(InternalStats.launchCount.rawValue)
    }

    /**
     Keep track of how many times the app has successfully switched
     between different PHP versions.
     
     This is used to determine whether it is time to show the sponsor
     encouragement alert, but I'd like to include this stat somewhere
     else as well.
     */
    public static var successfulSwitchCount: Int {
        readInteger(InternalStats.switchCount.rawValue)
    }

    /**
     Did the user see the sponsor encouragement / thank you message?
     Annoying the user is the worst, so let's not show the message twice.
     */
    public static var didSeeSponsorEncouragement: Bool {
        readBool(InternalStats.didSeeSponsorEncouragement.rawValue)
    }

    public static var lastGlobalPhpVersion: String {
        readString(InternalStats.lastGlobalPhpVersion.rawValue) ?? ""
    }

    /**
     Increment the successful launch count. This should only be
     called when the user has not encountered ANY issues starting
     up the application.
     */
    public static func incrementSuccessfulLaunchCount() {
        write(Stats.successfulLaunchCount + 1, forKey: InternalStats.launchCount.rawValue)
    }

    /**
     Increment the successful switch count.
     */
    public static func incrementSuccessfulSwitchCount() {
        write(Stats.successfulSwitchCount + 1, forKey: InternalStats.switchCount.rawValue)
    }

    /**
     Persist which PHP version was active when you last used the app.
     */
    public static func persistCurrentGlobalPhpVersion(version: String) {
        write(version, forKey: InternalStats.lastGlobalPhpVersion.rawValue)
    }

    public static func clearCurrentGlobalPhpVersion() {
        write(nil, forKey: InternalStats.lastGlobalPhpVersion.rawValue)
    }

    /**
     Determine if the sponsor message should be displayed.
     
     The rationale behind this is simple, some of the stats
     increasing beyond a certain point indicate the app
     is being used.
     
     We evaluate, first:
     - Successful version switches
     OR
     - Successful starts of the application
     
     AND, of course, you must never have seen the alert before.
     (see `didSeeSponsorEncouragement`)
     */
    public static func evaluateSponsorMessageShouldBeDisplayed() {

        if App.shared.container.shell is TestableShell {
            return Log.info("A fake shell is in use, skipping sponsor alert.")
        }

        if App.isEarlyAccessBuild {
            return Log.info("Sponsor messages never apply to beta builds.")
        }

        if Stats.didSeeSponsorEncouragement {
            return Log.info("Awesome, the user has already seen the sponsor message.")
        }

        if Stats.successfulLaunchCount < 7 && Stats.successfulSwitchCount < 40 {
            return Log.info("It is too soon to see the sponsor message (launched \(Stats.successfulLaunchCount) " +
                            "times, switched \(Stats.successfulSwitchCount) times).")
        }

        Task { @MainActor in
            let donate = NVAlert()
                .withInformation(
                    title: "startup.sponsor_encouragement.title".localized,
                    subtitle: "startup.sponsor_encouragement.subtitle".localized,
                    description: "startup.sponsor_encouragement.desc".localized
                )
                .withPrimary(text: "startup.sponsor_encouragement.accept".localized)
                .withSecondary(text: "startup.sponsor_encouragement.skip".localized)
                .withTertiary(text: "", action: { vc in
                    vc.close(with: .alertThirdButtonReturn)
                    NSWorkspace.shared.open(Constants.Urls.DonationPage)
                }).didSelectPrimary(urgency: .normalRequestAttention)

            if donate {
                Log.info("The user is an absolute badass for choosing this option. Thank you.")
                NSWorkspace.shared.open(Constants.Urls.DonationPayment)
            }

            write(true, forKey: InternalStats.didSeeSponsorEncouragement.rawValue)
        }
    }
}
