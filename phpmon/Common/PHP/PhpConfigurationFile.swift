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
    var extensions: [PhpExtension]

    /// The actual, structured content of the configuration file.
    var content: Config

    /// The original lines of the file.
    var lines: [String]

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
        self.lines = contents.components(separatedBy: "\n")
        self.extensions = PhpExtension.from(container, lines, filePath: path)
        self.content = Self.parseConfig(lines: lines)
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
    public func replace(key: String, value: String) throws {
        // Ensure that the key exists
        guard let item = getConfig(for: key) else {
            throw ReplacementErrors.missingKey
        }

        // Figure out what comes after the assignment
        var components = self
            .lines[item.lineIndex]
            .components(separatedBy: "=")

        // Replace the value with the new one
        components[1] = components[1]
            .replacing(item.value, with: value)

        // Replace the specific line
        self.lines[item.lineIndex] = components.joined(separator: "=")

        // Ensure the watchers aren't tripped up by config changes
        ConfigWatchManager.ignoresModificationsToConfigValues = true

        // Finally, join the string and save the file atomatically again
        try self.lines.joined(separator: "\n")
            .write(toFile: self.filePath, atomically: true, encoding: .utf8)

        // Ensure watcher behaviour is reverted
        ConfigWatchManager.ignoresModificationsToConfigValues = false

        // Reload the original file
        self.reload()
    }

    public func reload() {
        self.lines = try! String(contentsOfFile: self.filePath)
            .components(separatedBy: "\n")
        self.extensions = PhpExtension.from(container, lines, filePath: self.filePath)
        self.content = Self.parseConfig(lines: lines)
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
