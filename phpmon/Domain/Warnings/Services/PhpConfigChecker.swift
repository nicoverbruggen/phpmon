//
//  PhpConfigChecker.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpConfigChecker {

    public static var shared = PhpConfigChecker()

    var missing: [String] = []

    public func check() {
        missing = []

        let shouldExist = [
            "php.ini",
            "php-fpm.conf",
            "php-fpm.d/valet-fpm.conf"
        ]

        for version in PhpEnv.shared.availablePhpVersions {
            for file in shouldExist {
                let fullFilePath = Paths.etcPath.appending("/php/\(version)/\(file)")
                if !FileSystem.fileExists(fullFilePath) {
                    missing.append(fullFilePath)
                }
            }
        }

        if !missing.isEmpty {
            Log.warn("The following config file(s) were missing: \(missing)")
        }
    }
}
