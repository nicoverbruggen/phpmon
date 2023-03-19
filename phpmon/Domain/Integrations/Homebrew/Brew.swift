//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class Brew: ObservableObject {
    static let shared = Brew()

    init() {
        Task {
            // Asynchronously load available updates
            let items = await loadPhpVersions(loadOutdated: false)
            Task { @MainActor in
                self.phpVersions = items
            }
        }
    }

    @Published var phpVersions: [BrewFormula] = []

    /// The version of Homebrew that was detected.
    var version: VersionNumber?

    /// Determine which version of Homebrew is installed.
    public func determineVersion() async {
        let output = await Shell.pipe("\(Paths.brew) --version")
        self.version = try? VersionNumber.parse(output.out)

        if let version = version {
            Log.info("The user has Homebrew \(version.text) installed.")

            if version.major < 4 {
                Log.warn("Managing PHP versions is only supported with Homebrew 4 or newer!")
            }
        } else {
            Log.warn("The Homebrew version could not be determined.")
        }
    }

    /// Each formula for each PHP version that can be installed.
    public static var phpVersionFormulae = [
        "8.2": "php@8.2",
        "8.1": "php@8.1",
        "8.0": "php@8.0",
        "7.4": "shivammathur/php/php@7.4",
        "7.3": "shivammathur/php/php@7.3",
        "7.2": "shivammathur/php/php@7.2",
        "7.1": "shivammathur/php/php@7.1",
        "7.0": "shivammathur/php/php@7.0",
        "5.6": "shivammathur/php/php@5.6"
    ]

    public func loadPhpVersions(loadOutdated: Bool) async -> [BrewFormula] {
        var outdated: [OutdatedFormula]?

        if loadOutdated {
            let command = """
            \(Paths.brew) update >/dev/null && \
            \(Paths.brew) outdated --json --formulae
            """

            let rawJsonText = await Shell.pipe(command).out
                .data(using: .utf8)!
            outdated = try? JSONDecoder().decode(
                OutdatedFormulae.self,
                from: rawJsonText
            ).formulae.filter({ formula in
                formula.name.starts(with: "php")
            })
        }

        print(PhpEnv.shared.cachedPhpInstallations)

        return Self.phpVersionFormulae.map { (version, formula) in
            let fullVersion = PhpEnv.shared.cachedPhpInstallations[version]?.versionNumber.text
            var upgradeVersion: String?

            if let version = fullVersion {
                upgradeVersion = outdated?.first(where: { formula in
                    return formula.installed_versions.contains(version)
                })?.current_version
            }

            return BrewFormula(
                name: formula,
                displayName: "PHP \(version)",
                installedVersion: fullVersion,
                upgradeVersion: upgradeVersion
            )
        }.sorted { $0.displayName > $1.displayName }
    }
}
