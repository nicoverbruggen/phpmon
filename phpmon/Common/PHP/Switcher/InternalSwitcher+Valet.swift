//
//  InternalSwitcher+Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension InternalSwitcher {

    typealias FixApplied = Bool

    public func ensureValetConfigurationIsValidForPhpVersion(_ version: String) async -> FixApplied {
        // Early exit if Valet is not installed
        if !Valet.installed {
            assertionFailure("Cannot ensure that Valet configuration is valid if Valet is not installed.")
            return false
        }

        let corrections = [
            await self.disableDefaultPhpFpmPool(version),
            await self.ensureConfigurationFilesExist(version)
        ]

        return corrections.contains(true)
    }

    // MARK: - PHP FPM pool

    public func disableDefaultPhpFpmPool(_ version: String) async -> FixApplied {
        let pool = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"

        if FileSystem.fileExists(pool) {
            Log.info("A default `www.conf` file was found in the php-fpm.d directory for PHP \(version).")
            let existing = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf"
            let new = "\(Paths.etcPath)/php/\(version)/php-fpm.d/www.conf.disabled-by-phpmon"
            do {
                if FileSystem.fileExists(new) {
                    Log.info("A moved `www.conf.disabled-by-phpmon` file was found for PHP \(version), "
                             + "cleaning up so the newer `www.conf` can be moved again.")
                    try FileSystem.remove(new)
                }
                try FileSystem.move(from: existing, to: new)
                Log.info("Success: A default `www.conf` file was disabled for PHP \(version).")
                return true
            } catch {
                Log.err(error)
                return false
            }
        }

        return false
    }

    func getExpectedConfigurationFiles(for version: String) -> [ExpectedConfigurationFile] {
        return [
            ExpectedConfigurationFile(
                destination: "/php-fpm.d/valet-fpm.conf",
                source: "/cli/stubs/etc-phpfpm-valet.conf",
                replacements: [
                    "VALET_USER": Paths.whoami,
                    "VALET_HOME_PATH": "~/.config/valet".replacingTildeWithHomeDirectory,
                    "valet.sock": "valet\(version.replacingOccurrences(of: ".", with: "")).sock"
                ],
                applies: { Valet.shared.version!.major > 2 }
            ),
            ExpectedConfigurationFile(
                destination: "/conf.d/error_log.ini",
                source: "/cli/stubs/etc-phpfpm-error_log.ini",
                replacements: [
                    "VALET_USER": Paths.whoami,
                    "VALET_HOME_PATH": "~/.config/valet".replacingTildeWithHomeDirectory
                ],
                applies: { return true }
            ),
            ExpectedConfigurationFile(
                destination: "/conf.d/php-memory-limits.ini",
                source: "/cli/stubs/php-memory-limits.ini",
                replacements: [:],
                applies: { return true }
            )
        ]
    }

    func ensureConfigurationFilesExist(_ version: String) async -> FixApplied {
        let files = self.getExpectedConfigurationFiles(for: version)

        // For each of the files, attempt to fix anything that is wrong
        let outcomes = files.map { file in
            let configFileExists = FileSystem.fileExists("\(Paths.etcPath)/php/\(version)/" + file.destination)

            if configFileExists {
                return false
            }

            Log.info("Config file `\(file.destination)` does not exist, will attempt to automatically fix!")

            if !file.applies() {
                return false
            }

            do {
                var contents = try FileSystem.getStringFromFile("~/.composer/vendor/laravel/valet" + file.source)

                for (original, replacement) in file.replacements {
                    contents = contents.replacingOccurrences(of: original, with: replacement)
                }

                try FileSystem.writeAtomicallyToFile(
                    "\(Paths.etcPath)/php/\(version)" + file.destination,
                    content: contents
                )
            } catch {
                Log.err("Automatically fixing \(file.destination) did not work.")
                return false
            }

            return true
        }

        // If any fixes were applied, return true
        return outcomes.contains(true)
    }

}

public struct ExpectedConfigurationFile {
    let destination: String
    let source: String
    let replacements: [String: String]
    let applies: () -> Bool
}
