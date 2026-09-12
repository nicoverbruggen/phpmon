//
//  InternalSwitcher+Valet.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension InternalSwitcher {
    typealias FixApplied = Bool

    @discardableResult
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

    // MARK: - Corrections

    public func disableDefaultPhpFpmPool(_ version: String) async -> FixApplied {
        let pool = "\(container.paths.etcPath)/php/\(version)/php-fpm.d/www.conf"

        let filesystem = container.filesystem!
        return await runBlocking {
            if filesystem.fileExists(pool) {
                Log.info("A default `www.conf` file was found in the php-fpm.d directory for PHP \(version).")
                let existing = pool
                let new = pool + ".disabled-by-phpmon"
                do {
                    if filesystem.fileExists(new) {
                        Log.info("A moved `www.conf.disabled-by-phpmon` file was found for PHP \(version), "
                                 + "cleaning up so the newer `www.conf` can be moved again.")
                        try filesystem.remove(new)
                    }
                    try filesystem.move(from: existing, to: new)
                    Log.info("Success: A default `www.conf` file was disabled for PHP \(version).")
                    return true
                } catch {
                    Log.err(error)
                    return false
                }
            }

            return false
        }
    }

    public func ensureConfigurationFilesExist(_ version: String) async -> FixApplied {
        let files = self.getExpectedConfigurationFiles(for: version)

        let filesystem = container.filesystem!
        let destination = "\(container.paths.etcPath)/php/\(version)"

        var repaired = false
        for file in files {
            let path = destination + file.destination
            let exists = await runBlocking { filesystem.fileExists(path) }
            guard !exists, file.applies() else { continue }

            let source = "~/.composer/vendor/laravel/valet" + file.source
            let replacements = file.replacements
            do {
                try await runBlocking {
                    var contents = try filesystem.getStringFromFile(source)
                    for (original, replacement) in replacements {
                        contents = contents.replacing(original, with: replacement)
                    }
                    try filesystem.writeAtomicallyToFile(path, content: contents)
                }
                repaired = true
            } catch {
                Log.err("Automatically fixing \(file.destination) did not work.")
            }
        }
        return repaired
    }

    // MARK: - Internals

    private func getExpectedConfigurationFiles(for version: String) -> [ExpectedConfigurationFile] {
        return [
            ExpectedConfigurationFile(
                destination: "/php-fpm.d/valet-fpm.conf",
                source: "/cli/stubs/etc-phpfpm-valet.conf",
                replacements: [
                    "VALET_USER": container.paths.whoami,
                    "VALET_HOME_PATH": "~/.config/valet".replacingTildeWithHomeDirectory,
                    "valet.sock": "valet\(version.replacing(".", with: "")).sock"
                ],
                applies: { (self.container.valet.version?.major ?? 0) > 2 }
            ),
            ExpectedConfigurationFile(
                destination: "/conf.d/error_log.ini",
                source: "/cli/stubs/etc-phpfpm-error_log.ini",
                replacements: [
                    "VALET_USER": container.paths.whoami,
                    "VALET_HOME_PATH": "~/.config/valet".replacingTildeWithHomeDirectory
                ],
                applies: { true }
            ),
            ExpectedConfigurationFile(
                destination: "/conf.d/php-memory-limits.ini",
                source: "/cli/stubs/php-memory-limits.ini",
                replacements: [:],
                applies: { true }
            )
        ]
    }

}

public struct ExpectedConfigurationFile {
    let destination: String
    let source: String
    let replacements: [String: String]
    let applies: () -> Bool
}
