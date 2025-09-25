//
//  Constants.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

struct Constants {

    /**
     The minimum version of Valet that is recommended.
     If the installed version is older, a notification will be shown
     every time the app launches (with a recommendation to upgrade).

     See also: https://github.com/laravel/valet/releases/tag/v2.16.2
     */
    static let MinimumRecommendedValetVersion = "2.16.2"

    /**
     The amount of seconds that is considered the threshold for
     PHP Monitor to mark any given launch as a "slow" launch.
     
     If the startup procedure was slow (or hangs), this message should
     be displayed. This is based on an appropriate launch time on a
     basic M1 Apple chip, with some margin for slower Intel chips.
     */
    static let SlowBootThresholdInterval: TimeInterval = 30.0

    /**
     PHP Monitor supplies a hardcoded list of PHP packages in its own
     PHP Version Manager. 

     This hardcoded list will expire and will need to be modified when
     the cutoff date occurs, which is when the `php` formula will
     become PHP 8.5, and a new build will need to be made.

     If users launch an older version of the app, then a warning
     will be displayed to let them know that certain operations
     will not work correctly and that they need to update their app.
     */
    static let PhpFormulaeCutoffDate = "2025-11-30" // YYYY-MM-DD

    /**
     * The PHP versions that are considered pre-release versions.
     * Past a certain date, an experimental version "graduates"
     * to a release version and is no longer marked as experimental.
     */
    static var ExperimentalPhpVersions: Set<String> {
        let releaseDates = [
            "8.5": Date.fromString(Self.PhpFormulaeCutoffDate),
            "8.4": Date.fromString("2024-11-22")
        ]

        return Set(releaseDates
            .filter { (_: String, date: Date?) in
                guard let date else {
                    return false
                }

                return date > Date.now
            }.map { (version: String, _: Date?) in
                return version
            })
    }

    /**
     The Homebrew services that should be automatically
     detected and show up in the list of managed services.
     */
    static let DetectedHomebrewServices: Set = [
        "mailhog",
        "mysql@",
        "postgresql@",
        "redis"
    ]

    /**
     * The PHP versions supported by this application.
     * Any other PHP versions are considered invalid.
     */
    static let DetectedPhpVersions: Set = [
        "5.6",
        "7.0", "7.1", "7.2", "7.3", "7.4",
        "8.0", "8.1", "8.2", "8.3", "8.4",
        "8.5" // DEV
    ]

    /**
     The PHP versions supported by each version of Valet.
     */
    static let ValetSupportedPhpVersionMatrix: [Int: Set] = [
        2: // Valet v2 has the broadest legacy support
        [
            "5.6",
            "7.0", "7.1", "7.2", "7.3", "7.4",
            "8.0", "8.1", "8.2"
        ],
        3: // Valet v3 dropped support for v5.6
        [
            "7.0", "7.1", "7.2", "7.3", "7.4",
            "8.0", "8.1", "8.2", "8.3", "8.4"
        ],
        4: // Valet v4 dropped support for v7.0
        [
            "7.1", "7.2", "7.3", "7.4",
            "8.0", "8.1", "8.2", "8.3", "8.4",
            "8.5" // DEV
        ]
    ]

    struct Urls {

        // phpmon.app URLs (these are aliased to redirect correctly)

        static let DonationPage = URL(
            string: "https://phpmon.app/sponsor"
        )!

        static let FrequentlyAskedQuestions = URL(
            string: "https://phpmon.app/faq"
        )!

        static let WikiPhpUnavailable = URL(
            string: "https://phpmon.app/php-unavailable"
        )!

        static let WikiPhpUpgrade = URL(
            string: "https://phpmon.app/php-upgrade"
        )!

        static let DonationPayment = URL(
            string: "https://phpmon.app/sponsor/now"
        )!

        static let EarlyAccessChangelog = URL(
            string: "https://phpmon.app/early-access/release-notes"
        )!

        // API endpoints (via api.phpmon.app)

        static let UpdateCheckEndpoint =  URL(
            string: "https://api.phpmon.app/api/v1/update-check"
        )!

        // GitHub URLs (do not alias these)

        static let GitHubReleases = URL(
            string: "https://github.com/nicoverbruggen/phpmon/releases"
        )!
    }

}
