//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
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

    var version: Version!
    var configuration: Configuration!
    var extensions: [PhpExtension]!
    
    // MARK: - Computed
    
    var formula: String {
        return (version.short == App.shared.brewPhpVersion) ? "php" : "php@\(version.short)"
    }
    
    // MARK: - Initializer

    init() {
        // Show information about the current version
        getVersion()
        
        // If an error occurred, exit early
        if (version.error) {
            configuration = Configuration()
            extensions = []
            return
        }
        
        // Load extension information
        let path = URL(fileURLWithPath: "\(Paths.etcPath)/php/\(version.short)/php.ini")
        extensions = PhpExtension.load(from: path)
        
        // Get configuration values
        configuration = Configuration(
            memory_limit: getByteCount(key: "memory_limit"),
            upload_max_filesize: getByteCount(key: "upload_max_filesize"),
            post_max_size: getByteCount(key: "post_max_size")
        )
        
        // Return a list of .ini files parsed after php.ini
        let paths = Command.execute(path: Paths.php, arguments: ["-r", "echo php_ini_scanned_files();"])
            .replacingOccurrences(of: "\n", with: "")
            .split(separator: ",")
            .map { String($0) }
        
        // See if any extensions are present in said .ini files
        paths.forEach { (iniFilePath) in
            let exts = PhpExtension.load(from: URL(fileURLWithPath: iniFilePath))
            if exts.count > 0 {
                extensions.append(contentsOf: exts)
            }
        }
    }
    
    /**
     When the app tries to retrieve the version, the installation is considered broken if the output is nothing,
     _or_ if the output contains the word "Warning" or "Error". In normal situations this should not be the case.
     */
    private func getVersion() -> Void {
        self.version = Version()
        
        let version = Command.execute(path: Paths.phpConfig, arguments: ["--version"], trimNewlines: true)
        
        if (version == "" || version.contains("Warning") || version.contains("Error")) {
            self.version.short = "💩 BROKEN"
            self.version.long = ""
            self.version.error = true
            return
        }
        
        // That's the long version
        self.version.long = version
        
        // Next up, let's strip away the minor version number
        let segments = self.version.long.components(separatedBy: ".")
        
        // Get the first two elements
        self.version.short = segments[0...1].joined(separator: ".")
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
        let value = Command.execute(path: Paths.php, arguments: ["-r", "echo ini_get('\(key)');"])
        
        // Check if the value is unlimited
        if (value == "-1") {
            return "∞"
        }
        
        // Check if the syntax is valid otherwise
        let regex = try! NSRegularExpression(pattern: #"^([0-9]*)(K|M|G|)$"#, options: [])
        let match = regex.matches(in: value, options: [], range: NSMakeRange(0, value.count)).first
        return (match == nil) ? "⚠️" : "\(value)B"
    }
    
    /**
     It is always possible that the system configuration for PHP-FPM has not been set up for Valet.
     This can occur when a user manually installs a new PHP version, but does not run `valet install`.
     In that case, we should alert the user!
     
     - Important: The underlying check is `checkPhpFpmStatus`, which can be run multiple times.
     This method actively presents a modal if said checks fails, so don't call this method too many times.
     */
    public func notifyAboutBrokenPhpFpm() {
        if !self.checkPhpFpmStatus() {
            DispatchQueue.main.async {
                Alert.notify(
                    message: "alert.php_fpm_broken.title".localized,
                    info: "alert.php_fpm_broken.info".localized,
                    style: .critical
                )
            }
        }
    }
    
    /**
     Determine if PHP-FPM is configured correctly.
     
     For PHP 5.6, we'll check if `valet.sock` is included in the main `php-fpm.conf` file, but for more recent
     versions of PHP, we can just check for the existence of the `valet-fpm.conf` file. If the check here fails,
     that means that Valet won't work properly.
     */
    private func checkPhpFpmStatus() -> Bool {
        if self.version.short == "5.6" {
            // The main PHP config file should contain `valet.sock` and then we're probably fine?
            let fileName = "\(Paths.etcPath)/php/5.6/php-fpm.conf"
            return Shell.pipe("cat \(fileName)").contains("valet.sock")
        }
        
        // Make sure to check if valet-fpm.conf exists. If it does, we should be fine :)
        return Shell.fileExists("\(Paths.etcPath)/php/\(self.version.short)/php-fpm.d/valet-fpm.conf")
    }
    
    // MARK: - Structs
    
    struct Version {
        var short = "???"
        var long = "???"
        var error = false
    }
    
    struct Configuration {
        var memory_limit = "???"
        var upload_max_filesize = "???"
        var post_max_size = "???"
    }
    
}
