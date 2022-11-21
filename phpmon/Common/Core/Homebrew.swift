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

class HomebrewFormula {
    let name: String
    let elevated: Bool

    init(_ name: String, elevated: Bool = true) {
        self.name = name
        self.elevated = elevated
    }
}
