//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVContainer

/**
 An installed version of PHP, that was detected by scanning the `/opt/php@version/bin` directory.
 
 When initialized, that version's .ini files are also scanned (for active or inactive extensions).
 Integrity checks can be performed to determine whether PHP-FPM is configured correctly.
 
 - Note: Each installation has a separate version number.
 Using `version.short` is advisable if you want to interact with Homebrew.
 */

@ContainerAccess
class ActivePhpInstallation {
    var version: VersionNumber!
    var limits: Limits!
    var iniFiles: [PhpConfigurationFile] = []

    var hasErrorState: Bool = false

    var extensions: [PhpExtension] {
        return iniFiles.flatMap { initFile in
            return initFile.extensions
        }
    }

    // MARK: - Computed

    var formula: String {
        return (version.short == PhpEnvironments.brewPhpAlias) ? "php" : "php@\(version.short)"
    }

    // MARK: - Initializer

    public static func load() -> ActivePhpInstallation? {
        if !FileSystem.fileExists(Paths.phpConfig) {
            return nil
        }

        return ActivePhpInstallation()
    }

    init(container: Container = App.shared.container) {
        self.container = container

        // Show information about the current version
        do {
            try determineVersion()
        } catch {
            fatalError("Could not determine or parse PHP version; aborting!")
        }

        // Initialize the list of ini files that are loaded
        iniFiles = []

        // If an error occurred, exit early
        if self.hasErrorState {
            limits = Limits()
            return
        }

        // Get configuration values
        limits = Limits(
            memory_limit: getByteCount(key: "memory_limit"),
            upload_max_filesize: getByteCount(key: "upload_max_filesize"),
            post_max_size: getByteCount(key: "post_max_size")
        )

        let paths = shell
            .sync("\(Paths.php) --ini | grep -E -o '(/[^ ]+\\.ini)'").out
            .split(separator: "\n")
            .map { String($0) }

        // See if any extensions are present in said .ini files
        paths.forEach { (iniFilePath) in
            if let file = PhpConfigurationFile.from(filePath: iniFilePath) {
                iniFiles.append(file)
            }
        }
    }

    /**
     When the app tries to retrieve the version, the installation is considered broken if the output is nothing,
     _or_ if the output contains the word "Warning" or "Error". In normal situations this should not be the case.
     */
    private func determineVersion() throws {
        let output = Command.execute(path: Paths.phpConfig, arguments: ["--version"], trimNewlines: true)

        self.hasErrorState = (output == "" || output.contains("Warning") || output.contains("Error"))

        self.version = try? VersionNumber.parse(output)
    }

    /**
     Retrieves the display value for a specific key in the `.ini` file.
     
     The following values are valid:
     * -1: unlimited (show the infinity icon)
     * 10000: an integer = amount of bytes
     * 1K, 1M, 1G = shorthand for kilobytes, megabytes and gigabytes
     
     If none of these notations are used, the _fallback_ value is used.
     We'll show an emoji to indicate something has gone wrong here.
     To clarify, B gets appended to valid values.
     As a result, "5M" (valid) becomes "5MB", and "5MB" (invalid) becomes ⚠️.
     
     - Parameter key: The key of the `ini` value that needs to be retrieved. For example, you can use `memory_limit`.
     */
    private func getByteCount(key: String) -> String {
        let value = Command.execute(path: Paths.php, arguments: ["-r", "echo ini_get('\(key)');"], trimNewlines: false)

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
