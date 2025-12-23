//
//  PhpConfigurationFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpConfigurationFile: CreatedFromFile {
    var container: Container

    struct ConfigValue {
        let lineIndex: Int
        let value: String
    }

    typealias Section = [String: ConfigValue]
    typealias Config = [String: Section]

    /// The file where this configuration file was located.
    let filePath: String

    /// The extensions found in this .ini file.
    private let _extensions: Locked<[PhpExtension]>
    var extensions: [PhpExtension] {
        get { _extensions.value }
        set { _extensions.value = newValue }
    }

    /// The actual, structured content of the configuration file.
    private let _content: Locked<Config>
    var content: Config {
        get { _content.value }
        set { _content.value = newValue }
    }

    /// The original lines of the file.
    private let _lines: Locked<[String]>
    var lines: [String] {
        get { _lines.value }
        set { _lines.value = newValue }
    }

    /** Resolves a PHP configuration file (.ini) */
    static func from(
        _ container: Container,
        filePath: String
    ) -> Self? {
        let path = filePath.replacing("~", with: container.paths.homePath)

        do {
            let fileContents = try container.filesystem.getStringFromFile(path)
            return Self.init(container, path: path, contents: fileContents)
        } catch {
            Log.warn("Could not read the PHP configuration file at: `\(filePath)`")
            return nil
        }
    }

    required init(_ container: Container, path: String, contents: String) {
        self.container = container
        self.filePath = path

        let lines = contents.components(separatedBy: "\n")

        // We only need to explicitly set our locks here
        self._lines = Locked(lines)
        self._extensions = Locked(PhpExtension.from(container, lines, filePath: path))
        self._content = Locked(Self.parseConfig(lines: lines))
    }

    // MARK: API

    public func has(key: String) -> Bool {
        return self.content.contains { (_: String, section: Section) in
            return section.keys.contains(key)
        }
    }

    public func get(for key: String) -> String? {
        return getConfig(for: key)?.value
    }

    public func getConfig(for key: String) -> ConfigValue? {
        for (_, section) in self.content where section.keys.contains(key) {
            return section[key]!
        }
        return nil
    }

    public enum ReplacementErrors: Error {
        case missingKey
        case missingFile
    }

    /**
     Replaces the value for a specific (existing) key with a new value.
     The key must exist for this to work.
     */
    public func replace(key: String, value: String) async throws {
        // Ensure that the key exists
        guard let item = getConfig(for: key) else {
            throw ReplacementErrors.missingKey
        }

        // Get a thread-safe copy to work with
        var localLines = lines

        // Figure out what comes after the assignment
        var components = localLines[item.lineIndex]
            .components(separatedBy: "=")

        // Replace the value with the new one
        components[1] = components[1]
            .replacing(item.value, with: value)

        // Replace the specific line in the local copy
        localLines[item.lineIndex] = components.joined(separator: "=")

        // Ensure the watchers aren't tripped up by config changes
        try await ConfigWatchManager.withSuspended {
            // Finally, join the string and save the file atomically
            try localLines.joined(separator: "\n")
                .write(toFile: self.filePath, atomically: true, encoding: .utf8)
        }

        self.lines = localLines

        // Reload the original file (which will update all properties atomically)
        self.reload()
    }

    public func reload() {
        let newLines = try! String(contentsOfFile: self.filePath)
            .components(separatedBy: "\n")

        // Update all properties atomically
        lines = newLines
        extensions = PhpExtension.from(container, newLines, filePath: self.filePath)
        content = Self.parseConfig(lines: newLines)
    }

    // MARK: Parsing Logic
    // Slightly modified from: https://gist.github.com/jetmind/f776c0d223e4ac6aec1ff9389e874553

    /**
     Attempts to parse the configuration file, based on an array of strings.
     Each string is a line from the configuration file.
     */
    private static func parseConfig(lines: [String]) -> Config {
        var config = Config()

        var currentSectionName = "main"

        for (index, line) in lines.enumerated() {
            let line = trim(line)

            if line.hasPrefix("[") && line.hasSuffix("]") {
                currentSectionName = parseSectionHeader(line)
            } else if let (key, value) = parseLine(line) {
                var section = config[currentSectionName] ?? [:]
                section[key] = ConfigValue(
                    lineIndex: index,
                    value: value
                )
                config[currentSectionName] = section
            }
        }

        return config
    }

    /**
     Remove all whitespace and additional characters from individual lines.
     */
    private static func trim(_ string: String) -> String {
        let whitespaces = CharacterSet(charactersIn: " \n\r\t")
        return string.trimmingCharacters(in: whitespaces)
    }

    /**
     It may prove beneficial to strip all comments, which can start with # or ;.
     In this case, strip both.
     */
    private static func stripComment(_ line: String) -> String {
        var line = line

        let characters: [String.Element] = ["#", ";"]

        for character in characters {
            // Only keep checking for comments as long as the line isn't empty
            if line.isEmpty {
                return line
            }

            // Check for the next comment character
            line = strip(character: character, line)
        }

        return line
    }

    /**
     Empties a line if it happens to be commented out, causing it to be ignored.
     */
    private static func strip(character: String.Element, _ line: String) -> String {
        let parts = line.split(
            separator: character,
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        if !parts.isEmpty {
            return String(parts[0])
        }

        return ""
    }

    /**
     Attempts to parse a section header. Requires the line to start with [ and end with ].
     */
    private static func parseSectionHeader(_ line: String) -> String {
        let from = line.index(after: line.startIndex)
        let to = line.index(before: line.endIndex)

        return line[from..<to]
    }

    /**
     Attempts to parse a regular line, which may contain a configuration value that is being set.
     */
    private static func parseLine(_ line: String) -> (String, String)? {
        let parts = stripComment(line)
            .split(separator: "=", maxSplits: 1)

        if parts.count == 2 {
            let k = trim(String(parts[0]))
            let v = trim(String(parts[1]))
            return (k, v)
        }

        return nil
    }

}
