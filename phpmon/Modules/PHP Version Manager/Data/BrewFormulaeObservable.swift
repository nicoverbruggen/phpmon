//
//  BrewPhpFormula.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/11/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewFormulaeObservable: ObservableObject {
    @Published var phpVersions: [BrewPhpFormula] = []

    var upgradeable: [BrewPhpFormula] {
        return phpVersions.filter { formula in
            formula.hasUpgrade
        }
    }
}
