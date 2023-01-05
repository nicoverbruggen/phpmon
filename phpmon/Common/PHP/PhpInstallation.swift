//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {

    var versionNumber: VersionNumber

    /**
     In order to determine details about a PHP installation, we’ll simply run `php-config --version`
     in the relevant directory.
     */
    init(_ version: String) {

        let phpConfigExecutablePath = "\(Paths.optPath)/php@\(version)/bin/php-config"
        self.versionNumber = VersionNumber.make(from: version)!

        if FileSystem.fileExists(phpConfigExecutablePath) {
            let longVersionString = Command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"],
                trimNewlines: false
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            // The parser should always work, or the string has to be very unusual.
            // If so, the app SHOULD crash, so that the users report what's up.
            self.versionNumber = try! VersionNumber.parse(longVersionString)
        }
    }

}
