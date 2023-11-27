//
//  BrewPhpExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct BrewPhpExtension: Hashable, Comparable {
    let name: String
    let phpVersion: String
    let isInstalled: Bool
    let path: String
    let dependencies: [String]

    var formulaName: String {
        return "\(name)@\(phpVersion)"
    }

    init(path: String, name: String, phpVersion: String) {
        self.path = path
        self.name = name
        self.phpVersion = phpVersion

        self.isInstalled = BrewPhpExtension.hasInstallationReceipt(
            for: "\(name)@\(phpVersion)"
        )

        self.dependencies = BrewPhpExtension.extractDependencies(from: path)
    }

    var hasAlternativeInstall: Bool {
        // Extension must be active
        let isActive = PhpEnvironments.shared.currentInstall?.extensions
            .contains(where: { $0.name == self.name }) ?? false

        return isActive && !isInstalled
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

    private static func extractDependencies(from path: String) -> [String] {
        let regexPattern = #"depends_on "(.*)""#
        var dependencies: [String] = []

        guard let content = try? FileSystem.getStringFromFile(path) else {
            return []
        }

        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    let dependencyName = String(content[range])
                    dependencies.append(dependencyName)
                }
            }
        } catch {
            return []
        }

        print(dependencies)

        return dependencies
    }
}
