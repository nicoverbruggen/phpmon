//
//  HomebrewOperationManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class HomebrewOperation {

    let installing: [BrewFormula]
    let upgrading: [BrewFormula]

    /**
     You can pass in which PHP versions need to be upgraded and which ones need to be installed.
     The process will be executed in two steps: first upgrades, then installations.
     Upgrades come first because... well, otherwise installations may very well break.
     Each version that is installed will need to be checked afterwards (if it is OK).
     */
    public init(
        upgrading: [BrewFormula],
        installing: [BrewFormula]
    ) {
        self.installing = installing
        self.upgrading = upgrading
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        try await self.upgradePackages()
        try await self.installPackages()
        try await self.repairBrokenPackages()
    }

    private func upgradePackages() async throws {
        if self.upgrading.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) upgrade \(self.upgrading.map { $0.name }.joined(separator: " "))
            """
    }

    private func installPackages() async throws {
        if self.installing.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) install \(self.upgrading.map { $0.name }.joined(separator: " ")) --force
            """
    }

    private func repairBrokenPackages() async throws {
        let requiringRepair = PhpEnv.shared.cachedPhpInstallations.values
            .filter({ !$0.isHealthy })
            .map { installation in
                let formula = "php@\(installation.versionNumber.short)"

                if installation.versionNumber.short == PhpEnv.brewPhpAlias {
                    return "php"
                }

                return formula
            }

        if requiringRepair.isEmpty {
            return
        }

        // If the health comes back as negative, attempt to reinstall
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) reinstall \(requiringRepair.joined(separator: " ")) --force
        """
    }

}
