//
//  ServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class ServicesManager: ObservableObject {

    static var shared = ServicesManager()

    private var formulae: [HomebrewFormula]

    @Published var services: [String: ServiceWrapper] = [:]

    init() {
        Log.info("Initializing ServicesManager...")

        formulae = [
            Homebrew.Formulae.php,
            Homebrew.Formulae.nginx,
            Homebrew.Formulae.dnsmasq
        ]

        let additionalFormulae = (Preferences.custom.services ?? []).map({ item in
            return HomebrewFormula(item, elevated: false)
        })

        formulae.append(contentsOf: additionalFormulae)

        services = Dictionary(uniqueKeysWithValues: formulae.map { ($0.name, ServiceWrapper(formula: $0)) })
    }

    public static func loadHomebrewServices() async {
        Task {
            let rootServiceNames = Self.shared.formulae
                .filter { $0.elevated }
                .map { $0.name }

            let rootJson = await Shell
                .pipe("sudo \(Paths.brew) services info --all --json")
                .out.data(using: .utf8)!

            let rootServices = try! JSONDecoder()
                .decode([HomebrewService].self, from: rootJson)
                .filter({ return rootServiceNames.contains($0.name) })

            Task { @MainActor in
                for service in rootServices {
                    Self.shared.services[service.name]!.service = service
                }
            }
        }

        Task {
            let userServiceNames = Self.shared.formulae
                .filter { !$0.elevated }
                .map { $0.name }

            let normalJson = await Shell
                .pipe("\(Paths.brew) services info --all --json")
                .out.data(using: .utf8)!

            let userServices = try! JSONDecoder()
                .decode([HomebrewService].self, from: normalJson)
                .filter({ return userServiceNames.contains($0.name) })

            Task { @MainActor in
                for service in userServices {
                    Self.shared.services[service.name]!.service = service
                }
            }
        }
    }

    /**
     Service wrapper, that contains the Homebrew JSON output (if determined) and the formula.
     This helps the app determine whether a service should run as an administrator or not.
     */
    public struct ServiceWrapper {
        public var formula: HomebrewFormula
        public var service: HomebrewService?

        init(formula: HomebrewFormula) {
            self.formula = formula
        }
    }

    /**
     Dummy data for preview purposes.
     */
    func withDummyServices(_ services: [String: Bool]) -> Self {
        for (service, enabled) in services {
            var item = ServiceWrapper(formula: HomebrewFormula(service))
            item.service = HomebrewService.dummy(named: service, enabled: enabled)
            self.services[service] = item
        }

        return self
    }
}
