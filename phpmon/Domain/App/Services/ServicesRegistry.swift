//
//  ServicesRegistry.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

final class ServicesRegistry {
    private let container: Container

    // Only ever touched from the main actor (this type is main-actor isolated under
    // the default flip, and all readers hop to the main actor first), so a plain
    // stored property suffices — no lock needed.
    private(set) var formulae: [HomebrewFormula]

    init(_ container: Container) {
        self.container = container
        self.formulae = Self.baseFormulae(for: container)
    }

    @discardableResult
    func reloadFormulae() async -> [HomebrewFormula] {
        let detectedServices = await AutoDetectableServices.shared.foundServices
        let formulae = resolveFormulae(detectedServices: detectedServices)
        self.formulae = formulae
        return formulae
    }

    private func resolveFormulae(detectedServices: Set<DetectableService>) -> [HomebrewFormula] {
        var formulae = Self.baseFormulae(for: container)
        var knownFormulaNames = Set(formulae.map(\.name))

        func appendIfMissing(_ formula: HomebrewFormula) {
            guard !knownFormulaNames.contains(formula.name) else {
                return
            }

            formulae.append(formula)
            knownFormulaNames.insert(formula.name)
        }

        if !Preferences.isEnabled(.hideAutoDetectedServicesInMenu) {
            detectedServices
                .map { HomebrewFormula($0.service, elevated: false, servicePrefix: $0.servicePrefix) }
                .forEach(appendIfMissing)
        }

        if let customServices = Preferences.custom.services, !customServices.isEmpty {
            customServices
                .map { HomebrewFormula($0, elevated: false) }
                .forEach(appendIfMissing)
        }

        return formulae
    }

    private static func baseFormulae(for container: Container) -> [HomebrewFormula] {
        let f = HomebrewFormulae(container)
        return [f.php, f.nginx, f.dnsmasq]
    }
}
