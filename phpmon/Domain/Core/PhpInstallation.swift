//
//  PhpInstallation.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInstallation {

    var version: Version
    var configuration: Configuration
    var extensions: [PhpExtension]
    
    // MARK: - Computed
    
    var formula: String {
        return (version.short == App.shared.brewPhpVersion) ? "php" : "php@\(version.short)"
    }
    
    // MARK: - Initializer

    init() {
        // Show information about the current version
        version = Self.getVersion()
        
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
            memory_limit: Self.getByteCount(key: "memory_limit"),
            upload_max_filesize: Self.getByteCount(key: "upload_max_filesize"),
            post_max_size: Self.getByteCount(key: "post_max_size")
        )
        
        // Determine which folder(s) to scan for additional files
        let iniFolder = Command.execute(path: Paths.phpConfig, arguments: ["--ini-dir"], trimNewlines: true)
        
        // Check the contents of the ini dir
        let enumerator = FileManager.default.enumerator(atPath: URL(fileURLWithPath: iniFolder).path)
        let filePaths = enumerator?.allObjects as! [String]
        
        filePaths.filter { $0.contains(".ini") }.forEach { (iniFileName) in
            let extensions = PhpExtension.load(from: URL(fileURLWithPath: "\(iniFolder)/\(iniFileName)"))
            if extensions.count > 0 {
                self.extensions.append(contentsOf: extensions)
            }
        }
    }
    
    /**
     When the app tries to retrieve the version, the installation is considered broken if the output is nothing,
     _or_ if the output contains the word "Warning" or "Error". In normal situations this should not be the case.
     */
    private static func getVersion() -> Version {
        var versionStruct = Version()
        let version = Command.execute(path: Paths.phpConfig, arguments: ["--version"], trimNewlines: true)
        
        if (version == "" || version.contains("Warning") || version.contains("Error")) {
            versionStruct.short = "💩 BROKEN"
            versionStruct.long = "";
            versionStruct.error = true
            return versionStruct;
        }
        
        // That's the long version
        versionStruct.long = version
        
        // Next up, let's strip away the minor version number
        let segments = versionStruct.long.components(separatedBy: ".")
        
        // Get the first two elements
        versionStruct.short = segments[0...1].joined(separator: ".")
        
        return versionStruct
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
    private static func getByteCount(key: String) -> String {
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
