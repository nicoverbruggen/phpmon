//
//  Constants.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/07/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Constants {
    
    /**
     * The PHP versions supported by this application.
     */
    static let SupportedPhpVersions = [
        "5.6", "7.0", "7.1", "7.2", "7.3", "7.4"
    ]
    
    /**
     Which php version is aliased as `php` to brew?
     This is usually the latest PHP version.
     */
    static let LatestPhpVersion = "7.4"
    
}
