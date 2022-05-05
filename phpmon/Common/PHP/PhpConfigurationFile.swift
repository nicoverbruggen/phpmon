//
//  PhpInitFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpConfigurationFile {

    typealias Section = [String: String]
    typealias Config = [String: Section]

    /// The file where this configuration file was located.
    let file: String

    /// The extensions found in this .ini file.
    let extensions: [PhpExtension]

    /// The actual content of the configuration file.
    var content: Config

    init(fileUrl: URL) {
        self.file = fileUrl.path

        let rawString = (try? String(contentsOf: fileUrl, encoding: .utf8)) ?? ""

        self.extensions = PhpExtension.load(from: fileUrl)

        self.content = Self.parseConfig(from: rawString.components(separatedBy: "\n"))

        dump(self)
    }

    // MARK: Parsing Logic
    // Slightly modified from: https://gist.github.com/jetmind/f776c0d223e4ac6aec1ff9389e874553

    /**
     Attempts to parse the configuration file, based on an array of strings.
     Each string is a line from the configuration file.
     */
    private static func parseConfig(from lines: [String]) -> Config {
        var config = Config()

        var currentSectionName = "main"

        for line in lines {
            let line = trim(line)

            if line.hasPrefix("[") && line.hasSuffix("]") {
                currentSectionName = parseSectionHeader(line)
            } else if let (key, value) = parseLine(line) {
                var section = config[currentSectionName] ?? [:]
                section[key] = value
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
