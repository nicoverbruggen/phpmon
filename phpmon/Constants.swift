//
//  Constants.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Constants {
    
    /**
     * The latest PHP version that is considered to be stable at the time of release.
     * This version number is currently not used (only as a default fallback).
     */
    static let LatestStablePhpVersion = "8.1"
    
    /**
     * The PHP versions supported by this application.
     * Versions that do not appear in this array are omitted from the list.
     */
    static let SupportedPhpVersions = [
        // ====================
        // STABLE RELEASES
        // ====================
        // Versions of PHP that are stable and are supported.
        "5.6",
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
    

    
}
