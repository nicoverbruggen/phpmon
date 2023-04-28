//
//  HomebrewOperationManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class HomebrewOperation {

    let installing: [String]
    let upgrading: [String]

    /**
     You can pass in which PHP versions need to be upgraded and which ones need to be installed.
     The process will be executed in two steps: first upgrades, then installations.
     Upgrades come first because... well, otherwise installations may very well break.
     Each version that is installed will need to be checked afterwards (if it is OK).
     */
    public init(
        upgrading: [String],
        installing: [String]
    ) {
        self.installing = installing
        self.upgrading = upgrading
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        try await self.upgradePackages()
        try await self.installPackages()
    }

    private func upgradePackages() async throws {
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) upgrade \(self.upgrading.joined(separator: " "))
            """

        print(command)
    }

    private func installPackages() async throws {
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) install \(self.upgrading.joined(separator: " ")) --force
            """

        print(command)
    }

    private func determineHealth(formula: String) -> Bool {
        #warning("Should return proper health")
        return false

        // If the health comes back as negative, attempt to reinstall
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) reinstall \(formula) --force
        """
    }

}
