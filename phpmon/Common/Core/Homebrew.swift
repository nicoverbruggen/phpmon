//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class Homebrew {
    static var fake: Bool = false

    struct Formulae {
        static var php: HomebrewFormula {
            if Homebrew.fake {
                return HomebrewFormula("php", elevated: true)
            }

            if PhpEnv.shared.homebrewPackage == nil {
                fatalError("You must either load the HomebrewPackage object or call `fake` on the Homebrew class.")
            }

            return HomebrewFormula(PhpEnv.phpInstall.formula, elevated: true)
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
