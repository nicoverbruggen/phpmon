//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 An installed version of PHP, that was detected by scanning the `/opt/php@version/bin` directory.

 When initialized, that version's .ini files are also scanned (for active or inactive extensions).
 Integrity checks can be performed to determine whether PHP-FPM is configured correctly.

 - Note: Each installation has a separate version number.
 Using `version.short` is advisable if you want to interact with Homebrew.
 */

class ActivePhpInstallation {

    // MARK: - Container

    var container: Container

    // MARK: - Variables

    var version: VersionNumber!
    var limits: Limits!
    var iniFiles: [PhpConfigurationFile] = []
    var hasErrorState: Bool = false

    // MARK: - Computed

    var extensions: [PhpExtension] {
        return iniFiles.flatMap { initFile in
            return initFile.extensions
        }
    }

    var formula: String {
        return (version.short == PhpEnvironments.brewPhpAlias) ? "php" : "php@\(version.short)"
    }

    // MARK: - Detection

    /**
     The raw, `Sendable` result of probing the currently linked PHP installation.

     All blocking I/O (running `php-config --version`, the `ini_get` probes,
     `php --ini` and reading the .ini files) happens when this probe is created.
     The main-actor `ActivePhpInstallation` model is then built from the probe
     without further I/O, which keeps the blocking work off the main thread
     (see `load`).
     */
    nonisolated struct Probe: Sendable {
        /// Whether the `php-config` binary exists at all. When it does not,
        /// there is no linked installation and no model should be built.
        let phpConfigExists: Bool

        /// Output of `php-config --version`.
        let versionOutput: String

        /// Raw `ini_get` outputs; nil when the installation is in an error state
        /// (matching the previous behavior of skipping these probes entirely).
        let memoryLimit: String?
        let uploadMaxFilesize: String?
        let postMaxSize: String?

        /// The contents of the .ini files reported by `php --ini`.
        let iniFiles: [PhpConfigurationFile.Snapshot]

        init(_ container: Container) {
            self.phpConfigExists = container.filesystem.fileExists(container.paths.phpConfig)

            guard phpConfigExists else {
                self.versionOutput = ""
                (self.memoryLimit, self.uploadMaxFilesize, self.postMaxSize) = (nil, nil, nil)
                self.iniFiles = []
                return
            }

            self.versionOutput = container.command.execute(
                path: container.paths.phpConfig,
                arguments: ["--version"],
                trimNewlines: true
            )

            // When the version output is broken, the installation is in an error
            // state: don't run any further probes (same early exit as before).
            guard !Self.indicatesErrorState(versionOutput) else {
                (self.memoryLimit, self.uploadMaxFilesize, self.postMaxSize) = (nil, nil, nil)
                self.iniFiles = []
                return
            }

            self.memoryLimit = Self.iniGet(container, key: "memory_limit")
            self.uploadMaxFilesize = Self.iniGet(container, key: "upload_max_filesize")
            self.postMaxSize = Self.iniGet(container, key: "post_max_size")

            let iniFilePaths = container.shell
                .sync("\(container.paths.php) --ini | grep -E -o '(/[^ ]+\\.ini)'").out
                .split(separator: "\n")
                .map { String($0) }

            self.iniFiles = PhpConfigurationFile.Snapshot.read(container, filePaths: iniFilePaths)
        }

        /**
         The installation is considered broken if the version output is nothing,
         _or_ if the output contains the word "Warning" or "Error". In normal
         situations this should not be the case.
         */
        static func indicatesErrorState(_ versionOutput: String) -> Bool {
            return versionOutput == ""
                || versionOutput.contains("Warning")
                || versionOutput.contains("Error")
        }

        private static func iniGet(_ container: Container, key: String) -> String {
            return container.command.execute(
                path: container.paths.php,
                arguments: ["-r", "echo ini_get('\(key)');"],
                trimNewlines: false
            )
        }
    }

    // MARK: - Initializer

    /**
     Loads the currently linked PHP installation, running all blocking probe I/O
     on the concurrent pool so the main actor is never blocked.
     */
    public static func load(_ container: Container) async -> ActivePhpInstallation? {
        let probe = await offMain { Probe(container) }

        guard probe.phpConfigExists else {
            return nil
        }

        return ActivePhpInstallation(container, probe: probe)
    }

    /**
     Blocking variant of `load`, for use against **fake containers only** (test
     bootstrap in `Container.overrideFake`), where the fake leaf services return
     instantly. Production code must use `load` to keep the main actor free.
     */
    public static func loadSync(_ container: Container) -> ActivePhpInstallation? {
        let probe = Probe(container)

        guard probe.phpConfigExists else {
            return nil
        }

        return ActivePhpInstallation(container, probe: probe)
    }

    /**
     The probe contains all data read from disk; this initializer only parses.
     */
    init(_ container: Container, probe: Probe) {
        self.container = container

        // Show information about the current version
        determineVersion(probe)

        // Initialize the list of ini files that are loaded
        iniFiles = []

        // If an error occurred, exit early
        if self.hasErrorState {
            limits = Limits()
            return
        }

        // Get configuration values
        limits = Limits(
            memory_limit: displayByteCount(probe.memoryLimit ?? ""),
            upload_max_filesize: displayByteCount(probe.uploadMaxFilesize ?? ""),
            post_max_size: displayByteCount(probe.postMaxSize ?? "")
        )

        // See if any extensions are present in the .ini files that were read
        probe.iniFiles.forEach { snapshot in
            iniFiles.append(PhpConfigurationFile.from(container, snapshot: snapshot))
        }
    }

    /**
     When the app tries to retrieve the version, the installation is considered broken if the output is nothing,
     _or_ if the output contains the word "Warning" or "Error". In normal situations this should not be the case.
     */
    private func determineVersion(_ probe: Probe) {
        self.hasErrorState = Probe.indicatesErrorState(probe.versionOutput)

        self.version = try? VersionNumber.parse(probe.versionOutput)
    }

    /**
     Formats the display value for a raw `ini_get` output.

     The following values are valid:
     * -1: unlimited (show the infinity icon)
     * 10000: an integer = amount of bytes
     * 1K, 1M, 1G = shorthand for kilobytes, megabytes and gigabytes

     If none of these notations are used, the _fallback_ value is used.
     We'll show an emoji to indicate something has gone wrong here.
     To clarify, B gets appended to valid values.
     As a result, "5M" (valid) becomes "5MB", and "5MB" (invalid) becomes ⚠️.

     - Parameter value: The raw value of the `ini` key, as read by the probe.
     */
    private func displayByteCount(_ value: String) -> String {
        // Check if the value is unlimited
        if value == "-1" {
            return "∞"
        }

        if value.isEmpty {
            return "⚠️"
        }

        // Check if the syntax is valid otherwise
        let regex = try! NSRegularExpression(pattern: #"^([0-9]*)(K|M|G|)$"#, options: [])

        let match = regex.matches(
            in: value, options: [],
            range: NSRange(location: 0, length: value.count)
        ).first

        return (match == nil) ? "⚠️" : "\(value)B"
    }

    // MARK: - Structs

    /**
     Struct containing information about the limits of the current PHP installation.
     Includes: memory limit, max upload size and max post size.
     */
    struct Limits {
        var memory_limit = "???"
        var upload_max_filesize = "???"
        var post_max_size = "???"
    }

}
