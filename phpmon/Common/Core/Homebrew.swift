//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class Homebrew {
    struct Formulae {
        static var php: HomebrewFormula {
            if PhpEnv.shared.homebrewPackage == nil {
                fatalError("You must either load the HomebrewPackage object or call `fake` on the Homebrew class.")
            }

            guard let install = PhpEnv.phpInstall else {
                return HomebrewFormula("php", elevated: true)
            }

            return HomebrewFormula(install.formula, elevated: true)
        }

        static var nginx: HomebrewFormula {
            return HomebrewDiagnostics.usesNginxFullFormula
                ? HomebrewFormula("nginx-full", elevated: true)
                : HomebrewFormula("nginx", elevated: true)
        }

        static var dnsmasq: HomebrewFormula {
            return HomebrewFormula("dnsmasq", elevated: true)
        }
    }
}

class HomebrewFormula: Equatable, Hashable {
    let name: String
    let elevated: Bool

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
