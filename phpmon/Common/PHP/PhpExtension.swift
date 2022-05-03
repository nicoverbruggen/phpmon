//
//  PhpExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/01/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 A PHP extension that was detected in the php.ini file.
 Please note that the extension may be disabled.
 
 - Note: You need to know more about regular expressions to be able to deal with these NSRegularExpression
 instances. You can find more information here: https://nshipster.com/swift-regular-expressions/
 */
class PhpExtension {

    /// The file where this extension was located.
    var file: String

    /// The original string that was used to determine this extension is active.
    var line: String

    /// The name of the extension. This is always identical to the name found in the original string.
    /// If you want to display this name, capitalize this.
    var name: String

    /// Whether the extension has been enabled.
    var enabled: Bool

    /// The file where this extension was located, but only the filename, not the full path to the .ini file.
    var fileNameOnly: String {
        return String(file.split(separator: "/").last ?? "php.ini")
    }

    // swiftlint:disable line_length
    /**
     This regular expression will allow us to identify lines which activate an extension.
     
     It will match the following items:
     
     * `extension="name.so"`
     * `zend_extension="name.so"`
     * `; extension="name.so"`
     * `; zend_extension="name.so"`
     
     - Note: Extensions that are disabled in a different way will not be detected. This is intentional.
     */
    static let extensionRegex = #"^(extension|zend_extension|;(\s?)extension|;(\s?)zend_extension)(\s?)(=)(\s?)(?<name>["]?(?:\/?.\/?)+(?:\.so)"?)$"#
    // swiftlint:enable line_length

    /**
     When registering an extension, we do that based on the line found inside the .ini file.
     */
    init(_ line: String, file: String) {
        let regex = try! NSRegularExpression(pattern: Self.extensionRegex, options: [])
        let match = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count)).first
        let range = Range(match!.range(withName: "name"), in: line)!

        self.line = line

        let fullPath = String(line[range])
            .replacingOccurrences(of: "\"", with: "") // replace excess "
            .replacingOccurrences(of: ".so", with: "") // replace excess .so

        self.name = String(fullPath.split(separator: "/").last!) // take last segment

        self.enabled = !line.contains(";")
        self.file = file
    }

    /**
     This simply toggles the extension in the .ini file.
     You may need to restart the other services in order for this change to apply.
     */
    func toggle() {
        let newLine = enabled
            // DISABLED: Commented out line
            ? "; \(line)"
            // ENABLED: Line where the comment delimiter (;) is removed
            : line.replacingOccurrences(of: "; ", with: "")

        sed(file: file, original: line, replacement: newLine)

        enabled.toggle()
    }

    // MARK: - Static Methods

    /**
     This method will attempt to identify all extensions in the .ini file at a certain URL.
     */
    static func load(from path: URL) -> [PhpExtension] {
        let file = try? String(contentsOf: path, encoding: .utf8)

        if file == nil {
            Log.err("There was an issue reading the file. Assuming no extensions were found.")
            return []
        }

        return file!.components(separatedBy: "\n")
            .filter {
                return $0.range(of: Self.extensionRegex, options: .regularExpression) != nil
            }
            .map {
                return PhpExtension($0, file: path.path)
            }
    }

}
