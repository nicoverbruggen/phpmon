//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

struct HomebrewFormulae {

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Variables

    var php: HomebrewFormula {
        if container.phpEnvs.homebrewPackage == nil {
            return HomebrewFormula("php", elevated: true)
        }

        guard let install = container.phpEnvs.phpInstall else {
            return HomebrewFormula("php", elevated: true)
        }

        return HomebrewFormula(install.formula, elevated: true)
    }

    var nginx: HomebrewFormula {
        return BrewDiagnostics.shared.usesNginxFullFormula
        ? HomebrewFormula("nginx-full", elevated: true)
        : HomebrewFormula("nginx", elevated: true)
    }

    var dnsmasq: HomebrewFormula {
        return HomebrewFormula("dnsmasq", elevated: true)
    }
}

class HomebrewFormula: Equatable, Hashable, CustomStringConvertible {
    let name: String
    let elevated: Bool

    var description: String {
        return name
    }

    init(_ name: String, elevated: Bool = true) {
        self.name = name
        self.elevated = elevated
    }

    static func == (lhs: HomebrewFormula, rhs: HomebrewFormula) -> Bool {
        return lhs.elevated == rhs.elevated && lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(elevated)
    }
}
