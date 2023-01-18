//
//  Constants.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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
     * The PHP versions supported by this application.
     * Any other PHP versions are considered invalid.
     */
    static let DetectedPhpVersions: Set = [
        "5.6",
        "7.0", "7.1", "7.2", "7.3", "7.4",
        "8.0", "8.1", "8.2", "8.3"
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
            "8.0", "8.1", "8.2",
            "8.3" // dev
        ],
        4: // Valet v4 dropped support for v7.0-v7.3
        [
            "7.4",
            "8.0", "8.1", "8.2",
            "8.3" // dev
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

        static let DonationPayment = URL(
            string: "https://phpmon.app/sponsor/now"
        )!

        // GitHub URLs (do not alias these)

        static let GitHubReleases = URL(
            string: "https://github.com/nicoverbruggen/phpmon/releases"
        )!

        static let StableBuildCaskFile = URL(
            string: "https://raw.githubusercontent.com/nicoverbruggen/homebrew-cask/master/Casks/phpmon.rb"
        )!

        static let DevBuildCaskFile = URL(
            string: "https://raw.githubusercontent.com/nicoverbruggen/homebrew-cask/master/Casks/phpmon-dev.rb"
        )!

    }

}
