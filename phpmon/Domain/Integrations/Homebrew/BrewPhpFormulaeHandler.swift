//
//  BrewFormulaeHandler.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol HandlesBrewPhpFormulae {
    var container: Container { get }
    var formulae: BrewFormulaeObservable { get }
    func loadPhpVersions(loadOutdated: Bool) async -> [BrewPhpFormula]
    func refreshPhpVersions(loadOutdated: Bool) async
}

extension HandlesBrewPhpFormulae {
    public func refreshPhpVersions(loadOutdated: Bool) async {
        let items = await loadPhpVersions(loadOutdated: loadOutdated)
        await container.phpEnvs.determinePhpAlias()
        formulae.phpVersions = items
    }
}

class BrewPhpFormulaeHandler: HandlesBrewPhpFormulae {
    // MARK: - Container

    let container: Container
    let formulae: BrewFormulaeObservable

    init(_ container: Container, formulae: BrewFormulaeObservable = BrewFormulaeObservable()) {
        self.container = container
        self.formulae = formulae
    }

    // MARK: - Methods

    public func loadPhpVersions(loadOutdated: Bool) async -> [BrewPhpFormula] {
        var outdated: [OutdatedFormula]?

        if loadOutdated {
            let command = """
            \(container.paths.brew) update >/dev/null && \
            \(container.paths.brew) outdated --json --formulae
            """

            let rawJsonText = await container.shell.pipe(command).out
                .data(using: .utf8)!
            outdated = try? JSONDecoder().decode(
                OutdatedFormulae.self,
                from: rawJsonText
            ).formulae.filter({ formula in
                formula.name.starts(with: "shivammathur/php/php") || formula.name.starts(with: "php")
            })
        }

        return Brew.phpVersionFormulae.map { (version, formula) in
            var fullVersion: String?
            var upgradeVersion: String?
            var isPrerelease: Bool = Constants.ExperimentalPhpVersions.contains(version)

            if let install = container.phpEnvs.cachedPhpInstallations[version] {
                fullVersion = install.versionNumber.text
                fullVersion = install.isPreRelease ? "\(fullVersion!)-dev" : fullVersion

                upgradeVersion = outdated?.first(where: { formula in
                    return formula.name.replacing("shivammathur/php/", with: "")
                        == install.formulaName.replacing("shivammathur/php/", with: "")
                })?.current_version

                isPrerelease = install.isPreRelease
            }

            return BrewPhpFormula(
                container,
                name: formula,
                displayName: "PHP \(version)",
                installedVersion: fullVersion,
                upgradeVersion: upgradeVersion,
                prerelease: isPrerelease
            )
        }.sorted { $0.displayName > $1.displayName }
    }
}
