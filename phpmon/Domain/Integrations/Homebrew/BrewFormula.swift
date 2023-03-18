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
}
