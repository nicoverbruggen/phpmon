//
//  BrewFormula.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewFormula {
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

    public func getHomebrewFolder() -> String {
        #error("This must return the path to the Homebrew folder")
    }

    public func isHealthy() -> Bool {
        #error("This must check if the PHP version works")
    }
}
