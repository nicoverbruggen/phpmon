//
//  Constants.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

struct Constants {

    /**
     * The latest PHP version that is considered to be stable at the time of release.
     * This version number is currently not used (only as a default fallback).
     */
    static let LatestStablePhpVersion = "8.2"

    /**
     The minimum version of Valet that is recommended.
     If the installed version is older, a notification will be shown
     every time the app launches (with a recommendation to upgrade).
     
     The minimum requirement is currently synced to PHP 8.1 compatibility.
     See also: https://github.com/laravel/valet/releases/tag/v2.16.2
     */
    static let MinimumRecommendedValetVersion = "2.16.2"

    /**
     * The PHP versions supported by this application.
     * Versions that do not appear in this array are omitted from the list.
     */
    static let SupportedPhpVersions = [
        // ====================
        // STABLE RELEASES
        // ====================
        // Versions of PHP that are stable and are supported.
        "5.6", // only supported when Valet 2.x is active
        "7.0",
        "7.1",
        "7.2",
        "7.3",
        "7.4",
        "8.0",
        "8.1",
        "8.2",

        // ====================
        // EXPERIMENTAL SUPPORT
        // ====================
        // Every release that supports the next release will always support the next
        // dev release. In this case, that means that the version below is detected.
        "8.3"
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
