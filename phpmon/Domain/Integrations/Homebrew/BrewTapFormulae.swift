//
//  BrewTapFormulae.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct BrewPhpExtension: Hashable, Comparable {
    let name: String
    let phpVersion: String
    let isInstalled: Bool

    var formulaName: String {
        return "\(name)@\(phpVersion)"
    }

    init(name: String, phpVersion: String) {
        self.name = name
        self.phpVersion = phpVersion
        self.isInstalled = BrewPhpExtension.hasInstallationReceipt(
            for: "\(name)@\(phpVersion)"
        )
    }

    static func hasInstallationReceipt(for formulaName: String) -> Bool {
        return FileSystem.fileExists("\(Paths.optPath)/\(formulaName)/INSTALL_RECEIPT.json")
    }

    static func < (lhs: BrewPhpExtension, rhs: BrewPhpExtension) -> Bool {
        return lhs.name < rhs.name
    }

    static func == (lhs: BrewPhpExtension, rhs: BrewPhpExtension) -> Bool {
        return lhs.name == rhs.name
    }
}

class BrewTapFormulae {
    public static func from(tap: String) -> [String: [BrewPhpExtension]] {
        let directory = "\(Paths.tapPath)/\(tap)/Formula"

        let files = try? FileSystem.getShallowContentsOfDirectory(directory)

        var availableExtensions = [String: [BrewPhpExtension]]()

        guard let files = files else {
            return availableExtensions
        }

        let regex = try! NSRegularExpression(pattern: "(\\w+)@(\\d+\\.\\d+)\\.rb")

        for file in files {
            let matches = regex.matches(in: file, range: NSRange(file.startIndex..., in: file))
            if let match = matches.first {
                if let phpExtensionRange = Range(match.range(at: 1), in: file),
                   let versionRange = Range(match.range(at: 2), in: file) {
                    // Determine what the extension's name is
                    let phpExtensionName = String(file[phpExtensionRange])
                    // Determine what PHP version this is for
                    let phpVersion = String(file[versionRange])

                    // Create a new BrewPhpExtension object, which will determine
                    // whether this extension is installed or not
                    let phpExtension = BrewPhpExtension(
                        name: phpExtensionName,
                        phpVersion: phpVersion
                    )

                    // Append the extension to the list
                    var extensions = availableExtensions[phpVersion, default: []]
                    extensions.append(phpExtension)
                    availableExtensions[phpVersion] = extensions.sorted()
                }
            }
        }

        return availableExtensions
    }
}
