//
//  Constants.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

struct Constants {

    /**
     * The latest PHP version that is considered to be stable at the time of release.
     * This version number is currently not used (only as a default fallback).
     */
    static let LatestStablePhpVersion = "8.1"

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

        // ====================
        // EXPERIMENTAL SUPPORT
        // ====================
        // Every release that supports the next release will always support the next
        // dev release. In this case, that means that the version below is detected.
        "8.2"
    ]

    struct Urls {

        static let DonationPayment = URL(
            string: "https://nicoverbruggen.be/sponsor#pay-now"
        )!
        static let DonationPage = URL(
            string: "https://nicoverbruggen.be/sponsor"
        )!
        static let FrequentlyAskedQuestions = URL(
            string: "https://github.com/nicoverbruggen/phpmon#%EF%B8%8F-faq--troubleshooting"
        )!

    }

}
