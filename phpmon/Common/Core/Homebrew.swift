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
                guard let lhsVersion = serviceVersion(for: lhs) else {
                    return true
                }

                guard let rhsVersion = serviceVersion(for: rhs) else {
                    return false
                }

                return isOlder(lhsVersion, than: rhsVersion)
            }
            ?? matches.first
    }

    private func serviceVersion(for service: HomebrewService) -> [Int]? {
        guard let servicePrefix, service.name.hasPrefix(servicePrefix) else {
            return nil
        }

        let version = service.name.dropFirst(servicePrefix.count)
        let components = version.split(separator: ".").compactMap { Int($0) }

        return components.isEmpty ? nil : components
    }

    private func isOlder(_ lhs: [Int], than rhs: [Int]) -> Bool {
        let componentCount = max(lhs.count, rhs.count)

        for index in 0..<componentCount {
            let lhsComponent = lhs.indices.contains(index) ? lhs[index] : 0
            let rhsComponent = rhs.indices.contains(index) ? rhs[index] : 0

            if lhsComponent != rhsComponent {
                return lhsComponent < rhsComponent
            }
        }

        return false
    }

    static func == (lhs: HomebrewFormula, rhs: HomebrewFormula) -> Bool {
        return lhs.elevated == rhs.elevated && lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(elevated)
    }
}
