//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {

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
        self.getVersion()
        
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
            memory_limit: self.getByteCount(key: "memory_limit"),
            upload_max_filesize: self.getByteCount(key: "upload_max_filesize"),
            post_max_size: self.getByteCount(key: "post_max_size")
        )
        
        // Return a list of .ini files parsed after php.ini
        let paths = Command.execute(path: Paths.php, arguments: ["-r", "echo php_ini_scanned_files();"])
            .replacingOccurrences(of: "\n", with: "")
            .split(separator: ",")
            .map { String($0) }
        
        // See if any extensions are present in said .ini files
        paths.forEach { (iniFilePath) in
            let extensions = PhpExtension.load(from: URL(fileURLWithPath: iniFilePath))
            if extensions.count > 0 {
                self.extensions.append(contentsOf: extensions)
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
     
     If none of these notations are used, the _fallback_ value is used. We'll show an emoji to indicate something has gone wrong here.
     To clarify, B gets appended to valid values. As a result, "5M" (valid) becomes "5MB", and "5MB" (invalid) becomes ⚠️.
     
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
    
    public func notifyAboutBrokenPhpFpm() {
        if !self.checkPhpFpmStatus() {
            DispatchQueue.main.async {
                Alert.notify(
                    message: "alert.php_fpm_broken.title".localized,
                    info: "alert.php_fpm_broken.info".localized
                )
            }
        }
    }
    
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
