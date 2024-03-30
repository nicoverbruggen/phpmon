//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {

    var versionNumber: VersionNumber

    var iniFiles: [PhpConfigurationFile] = []

    var isMissingBinary: Bool = false

    var isHealthy: Bool = true

    var extensions: [PhpExtension] {
        return self.iniFiles.flatMap({ $0.extensions })
    }

    var formulaName: String {
        let version = self.versionNumber.short

        if version == PhpEnvironments.brewPhpAlias {
            return "php"
        }

        return "php@\(self.versionNumber.short)"
    }

    /**
     In order to determine details about a PHP installation,
     we’ll simply run `php-config --version` in the relevant directory.
     */
    init(_ version: String) {
        let phpConfigExecutablePath = "\(Paths.optPath)/php@\(version)/bin/php-config",
            phpExecutablePath = "\(Paths.optPath)/php@\(version)/bin/php"

        versionNumber = VersionNumber.make(from: version)!

        determineVersion(phpConfigExecutablePath, phpExecutablePath)
        determineHealth(phpExecutablePath)
        determineIniFiles(phpExecutablePath)

        // Find all enabled extensions
        let enabled = self.extensions.filter({ $0.enabled }).map({ $0.name })
        Log.info("PHP \(versionNumber.short) has the following extensions enabled: \(enabled)")
    }

    private func determineVersion(_ phpConfigExecutablePath: String, _ phpExecutablePath: String) {
        if FileSystem.fileExists(phpConfigExecutablePath) {
            let longVersionString = Command.execute(
                path: phpConfigExecutablePath,
                arguments: ["--version"],
                trimNewlines: false
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            // The parser should always work, or the string has to be very unusual.
            // If so, the app SHOULD crash, so that the users report what's up.
            versionNumber = try! VersionNumber.parse(longVersionString)
        } else {
            // Keep track that the `php-config` binary is missing; this often means there's a mismatch between
            // the `php` version alias and the actual installed version (e.g. you haven't upgraded `php`)
            isMissingBinary = true
        }
    }

    private func determineHealth(_ phpExecutablePath: String) {
        if FileSystem.fileExists(phpExecutablePath) {
            let testCommand = Command.execute(
                path: phpExecutablePath,
                arguments: ["-v"],
                trimNewlines: false,
                withStandardError: true
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            // If the "dyld: Library not loaded" issue pops up, we have an unhealthy PHP installation
            // and we will need to reinstall this version of PHP via Homebrew.
            if testCommand.contains("Library not loaded") && testCommand.contains("dyld") {
                self.isHealthy = false
                Log.err("The PHP installation of \(self.versionNumber.short) is not healthy!")
            }
        }
    }

    private func determineIniFiles(_ phpExecutablePath: String) {
        let paths = ActiveShell.shared
            .sync("\(phpExecutablePath) --ini | grep -E -o '(/[^ ]+\\.ini)'").out
            .split(separator: "\n")
            .map { String($0) }

        // See if any extensions are present in said .ini files
        paths.forEach { (iniFilePath) in
            if let file = PhpConfigurationFile.from(filePath: iniFilePath) {
                iniFiles.append(file)
            }
        }
    }
}
