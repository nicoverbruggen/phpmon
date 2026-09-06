//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/11/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {

    // MARK: - Container

    var container: Container

    // MARK: - Variables

    var versionNumber: VersionNumber

    var iniFiles: [PhpConfigurationFile] = []

    var isPreRelease: Bool = false

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

    // MARK: - Detection

    /**
     The raw, `Sendable` result of probing a PHP installation on disk.

     All blocking I/O (running `php-config --version`, `php -v`, `php --ini` and
     reading the .ini files) happens when this probe is created. The main-actor
     `PhpInstallation` model is then built from the probe without further I/O,
     which keeps the blocking work off the main thread (see `detect`).
     */
    nonisolated struct Probe: Sendable {
        /// Output of `php-config --version`; nil when the binary is missing.
        let versionOutput: String?

        /// Output of `php -v` (including stderr); nil when the binary is missing.
        let healthOutput: String?

        /// The contents of the .ini files reported by `php --ini`.
        let iniFiles: [PhpConfigurationFile.Snapshot]

        init(_ container: Container, _ version: String) {
            let phpConfigExecutablePath = "\(container.paths.optPath)/php@\(version)/bin/php-config",
                phpExecutablePath = "\(container.paths.optPath)/php@\(version)/bin/php"

            self.versionOutput = container.filesystem.fileExists(phpConfigExecutablePath)
                ? container.command.execute(
                    path: phpConfigExecutablePath,
                    arguments: ["--version"],
                    trimNewlines: false
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                : nil

            self.healthOutput = container.filesystem.fileExists(phpExecutablePath)
                ? container.command.execute(
                    path: phpExecutablePath,
                    arguments: ["-v"],
                    trimNewlines: false,
                    withStandardError: true
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                : nil

            let iniFilePaths = container.shell
                .sync("\(phpExecutablePath) --ini | grep -E -o '(/[^ ]+\\.ini)'").out
                .split(separator: "\n")
                .map { String($0) }

            self.iniFiles = PhpConfigurationFile.Snapshot.read(container, filePaths: iniFilePaths)
        }
    }

    /**
     Detects details about the PHP installation for `version`, running all blocking
     probe I/O on the concurrent pool so the main actor is never blocked.
     */
    static func detect(_ container: Container, _ version: String) async -> PhpInstallation {
        let probe = await offMain { Probe(container, version) }
        return PhpInstallation(container, version, probe: probe)
    }

    /**
     In order to determine details about a PHP installation,
     we’ll simply run `php-config --version` in the relevant directory.

     The probe contains all data read from disk; this initializer only parses.
     Prefer `detect` (which probes off-main); passing a synchronously created
     probe is acceptable only against fake containers, where I/O is instant.
     */
    init(_ container: Container, _ version: String, probe: Probe) {
        self.container = container

        versionNumber = VersionNumber.make(from: version)!

        determineVersion(probe)
        determineHealth(probe)
        determineIniFiles(probe)

        // Find all enabled extensions
        let enabled = self.extensions.filter({ $0.enabled }).map({ $0.name })
        Log.info("PHP \(versionNumber.short) has the following extensions enabled: \(enabled)")
    }

    private func determineVersion(_ probe: Probe) {
        if let longVersionString = probe.versionOutput {
            guard let parsedVersion = try? VersionNumber.parse(longVersionString) else {
                // Retain the known Homebrew version so the installation remains available for repair.
                isHealthy = false
                Log.err("Could not parse php-config output for PHP \(versionNumber.short): \(String(reflecting: longVersionString))")
                return
            }

            versionNumber = parsedVersion
            isPreRelease = longVersionString.contains("-dev")
        } else {
            // Keep track that the `php-config` binary is missing; this often means there's a mismatch between
            // the `php` version alias and the actual installed version (e.g. you haven't upgraded `php`)
            isMissingBinary = true
        }
    }

    private func determineHealth(_ probe: Probe) {
        guard let testCommand = probe.healthOutput else {
            return
        }

        // The PHP executable did not return any output
        if testCommand.isEmpty
            || testCommand.contains("HANDLE_READ_FAILURE") {
            Log.err("No output. PHP \(self.versionNumber.short) is not healthy!")
            self.isHealthy = false
        }

        // The PHP executable crashed with an uncaught signal when we tried to run this
        if testCommand.contains("UNCAUGHT_SIGNAL") {
            Log.err("Uncaught signal, PHP \(self.versionNumber.short) is not healthy!")
            self.isHealthy = false
        }

        // If the "dyld: Library not loaded" issue pops up, we have an unhealthy PHP installation
        // and we will need to reinstall this version of PHP via Homebrew.
        if testCommand.contains("Library not loaded") && testCommand.contains("dyld") {
            Log.err("dyld error, PHP \(self.versionNumber.short) is not healthy!")
            self.isHealthy = false
        }
    }

    private func determineIniFiles(_ probe: Probe) {
        // See if any extensions are present in said .ini files
        probe.iniFiles.forEach { snapshot in
            iniFiles.append(PhpConfigurationFile.from(container, snapshot: snapshot))
        }
    }
}
