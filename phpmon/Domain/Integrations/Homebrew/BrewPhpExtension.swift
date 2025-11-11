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

    var extensionDependencies: [String] {
        return dependencies
            .filter {
                $0.contains("shivammathur/extensions/") && $0.contains("@\(phpVersion)")
            }
            .map {
                $0.replacing("shivammathur/extensions/", with: "")
                    .replacing("@\(phpVersion)", with: "")
            }
    }

    var formulaName: String {
        return "\(name)@\(phpVersion)"
    }

    init(_ container: Container, path: String, name: String, phpVersion: String) {
        self.path = path
        self.name = name
        self.phpVersion = phpVersion

        self.isInstalled = BrewPhpExtension.hasInstallationReceipt(
            container, for: "\(name)@\(phpVersion)"
        )

        self.dependencies = BrewPhpExtension.extractDependencies(
            container, from: path
        )
    }

    var hasAlternativeInstall: Bool {
        guard let php = App.shared.container.phpEnvs.cachedPhpInstallations[self.phpVersion] else {
            return false
        }

        let alreadyDiscovered = php.extensions.contains(where: { $0.name == self.name })

        return alreadyDiscovered && !isInstalled
    }

    internal func firstDependent(in exts: [BrewPhpExtension]) -> BrewPhpExtension? {
        return exts
            .filter({ $0.isInstalled })
            .first { $0.dependencies.contains("shivammathur/extensions/\(self.formulaName)") }
    }

    static func hasInstallationReceipt(_ container: Container, for formulaName: String) -> Bool {
        return container.filesystem.fileExists("\(container.paths.optPath)/\(formulaName)/INSTALL_RECEIPT.json")
    }

    static func < (lhs: BrewPhpExtension, rhs: BrewPhpExtension) -> Bool {
        return lhs.name < rhs.name
    }

    static func == (lhs: BrewPhpExtension, rhs: BrewPhpExtension) -> Bool {
        return lhs.name == rhs.name
    }

    private static func extractDependencies(_ container: Container, from path: String) -> [String] {
        let regexPattern = #"depends_on "(.*)""#
        var dependencies: [String] = []

        guard let content = try? container.filesystem.getStringFromFile(path) else {
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

        return dependencies
    }
}
