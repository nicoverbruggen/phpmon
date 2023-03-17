//
//  BrewFormula.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

struct BrewFormula {
    let name: String
    let installedVersion: String?
    let upgradeVersion: String?

    var isInstalled: Bool {
        return installedVersion != nil
    }

    var hasUpgrade: Bool {
        return upgradeVersion != nil
    }
}
