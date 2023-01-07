//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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
        return (version.short == PhpEnv.brewPhpAlias) ? "php" : "php@\(version.short)"
    }

    // MARK: - Initializer

    init() {
        // Show information about the current version
        do {
            try determineVersion()
        } catch {
            // TODO: In future versions of PHP Monitor, this should not crash
            fatalError("Could not determine or parse PHP version; aborting")
        }

        // Initialize the list of ini files that are loaded
        iniFiles = []

        // If an error occurred, exit early
        if self.hasErrorState {
            limits = Limits()
            return
        }

        // Load extension information
        let mainConfigurationFileUrl = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(version.short)/php.ini")

        if let file = PhpConfigurationFile.from(filePath: mainConfigurationFileUrl.path) {
            iniFiles.append(file)
        }

        // Get configuration values
        limits = Limits(
            memory_limit: getByteCount(key: "memory_limit"),
            upload_max_filesize: getByteCount(key: "upload_max_filesize"),
            post_max_size: getByteCount(key: "post_max_size")
        )

        // Return a list of .ini files parsed after php.ini
        let paths = Command.execute(
            path: Paths.php,
            arguments: ["-r", "echo php_ini_scanned_files();"],
            trimNewlines: false
        )
        .replacingOccurrences(of: "\n", with: "")
        .split(separator: ",")
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

        // Check if the syntax is valid otherwise
        let regex = try! NSRegularExpression(pattern: #"^([0-9]*)(K|M|G|)$"#, options: [])
        let match = regex.matches(in: value, options: [], range: NSRange(location: 0, length: value.count)).first
        return (match == nil) ? "⚠️" : "\(value)B"
    }

    /**
     Determine if PHP-FPM is configured correctly.
     
     For PHP 5.6, we'll check if `valet.sock` is included in the main `php-fpm.conf` file, but for more recent
     versions of PHP, we can just check for the existence of the `valet-fpm.conf` file. If the check here fails,
     that means that Valet won't work properly.
     */
    func checkPhpFpmStatus() async -> Bool {
        if self.version.short == "5.6" {
            // The main PHP config file should contain `valet.sock` and then we're probably fine?
            let fileName = "\(Paths.etcPath)/php/5.6/php-fpm.conf"
            return await Shell.pipe("cat \(fileName)").out
                .contains("valet.sock")
        }

        // Make sure to check if valet-fpm.conf exists. If it does, we should be fine :)
        return FileSystem.fileExists("\(Paths.etcPath)/php/\(self.version.short)/php-fpm.d/valet-fpm.conf")
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
