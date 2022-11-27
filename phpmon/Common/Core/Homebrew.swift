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
        static var php: String {
            return PhpEnv.phpInstall.formula
        }

        static var nginx: String {
            return HomebrewDiagnostics.usesNginxFullFormula ? "nginx-full" : "nginx"
        }

        static var dnsmasq: String {
            return "dnsmasq"
        }
    }
}
