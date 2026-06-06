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
    let servicePrefix: String?

    var description: String {
        return name
    }

    init(_ name: String, elevated: Bool = true, servicePrefix: String? = nil) {
        self.name = name
        self.elevated = elevated
        self.servicePrefix = servicePrefix
    }

    func matches(_ service: HomebrewService) -> Bool {
        if service.name == name {
            return true
        }

        guard let servicePrefix else {
            return false
        }

        return service.name.hasPrefix(servicePrefix)
    }

    func latestService(from services: [HomebrewService]) -> HomebrewService? {
        let matches = services.filter(matches)

        guard let servicePrefix else {
            return matches.first
        }

        return matches
            .filter { $0.name.hasPrefix(servicePrefix) }
            .max { lhs, rhs in
                let lhsVersion = String(lhs.name.dropFirst(servicePrefix.count))
                let rhsVersion = String(rhs.name.dropFirst(servicePrefix.count))

                return lhsVersion.versionCompare(rhsVersion) == .orderedAscending
            }
            ?? matches.first
    }

    static func == (lhs: HomebrewFormula, rhs: HomebrewFormula) -> Bool {
        return lhs.elevated == rhs.elevated && lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(elevated)
    }
}
