//
//  CaskFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct CaskFile {
    var properties: [String: String]

    var name: String {
        return self.properties["name"]!
    }
    var url: String {
        return self.properties["url"]!
    }
    var sha256: String {
        return self.properties["sha256"]!
    }
    var version: String {
        return self.properties["version"]!
    }

    private static func loadFromApi(_ url: URL) async -> String {
        if App.hasLoadedTestableConfiguration {
            return await Shell.pipe("curl -s --max-time 10 '\(url.absoluteString)'").out
        } else {
            return await Shell.pipe("""
                curl -s --max-time 10 \
                -H "User-Agent: phpmon-curl/1.0" \
                -H "X-phpmon-version: \(App.shortVersion) (\(App.bundleVersion))" \
                -H "X-phpmon-os-version: \(App.macVersion)" \
                -H "X-phpmon-bundle-id: \(App.identifier)" \
                '\(url.absoluteString)'
            """).out
        }
    }

    public static func from(url: URL) async -> CaskFile? {
        var string: String?

        if url.scheme == "file" {
            string = try? String(contentsOf: url)
        } else {
            string = await CaskFile.loadFromApi(url)
        }

        guard let string else {
            Log.err("The content of the URL for the CaskFile could not be retrieved")
            return nil
        }

        let lines = string.split(separator: "\n")
            .map { line in
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { $0 != "" }

        if lines.count < 4 {
            Log.err("The CaskFile is <4 lines long, which is too short")
            return nil
        }

        if !lines.first!.starts(with: "cask") || !lines.last!.starts(with: "end") {
            Log.err("The CaskFile does not start with 'cask' or does not end with 'end'")
            return nil
        }

        var props: [String: String] = [:]

        let regex = try! NSRegularExpression(pattern: "(\\w+)\\s+'([^']+)'")

        for line in lines {
            if let match = regex.firstMatch(
                in: String(line),
                range: NSRange(location: 0, length: line.utf16.count)
            ) {
                let keyRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                let key = (line as NSString).substring(with: keyRange)
                let value = (line as NSString).substring(with: valueRange)
                props[key] = value
            }
        }

        for required in ["version", "sha256", "url", "name"] where !props.keys.contains(required) {
            Log.err("Property '\(required)' expected on CaskFile, assuming CaskFile is invalid")
            return nil
        }

        return CaskFile(properties: props)
    }
}
