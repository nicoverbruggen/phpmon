//
//  BrewFormula.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct BrewFormula {
    /// Name of the formula.
    let name: String

    /// The human readable name for this formula.
    let displayName: String

    /// The version of the formula that is currently installed.
    let installedVersion: String?

    /// The upgrade that is currently available, if it exists.
    let upgradeVersion: String?

    /// Whether the formula is currently installed.
    var isInstalled: Bool {
        return installedVersion != nil
    }

    /// Whether the formula can be upgraded.
    var hasUpgrade: Bool {
        return upgradeVersion != nil
    }

    /// The associated Homebrew folder with this PHP formula.
    var homebrewFolder: String {
        let resolved = name
            .replacingOccurrences(of: "shivammathur/php/", with: "")
            .replacingOccurrences(of: "php@" + PhpEnv.brewPhpAlias, with: "php")

        return "\(Paths.optPath)/\(resolved)/bin"
    }

    /// The short version associated with this formula, if installed.
    var shortVersion: String? {
        guard let version = self.installedVersion else {
            return nil
        }

        return VersionNumber.make(from: version)?.short ?? nil
    }

    /**
     * Determines if this PHP installation is healthy.
     * Uses the cached installation health check as basis.
     */
    public func isHealthy() -> Bool? {
        guard let shortVersion = self.shortVersion else {
            return nil
        }

        return PhpEnv.shared.cachedPhpInstallations[shortVersion]?.isHealthy ?? nil
    }
}
