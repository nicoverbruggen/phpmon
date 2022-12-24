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

    @ObservedObject static var shared: ServicesManager = ValetServicesManager()

    @Published var services = [ServiceWrapper]()

    subscript(name: String) -> ServiceWrapper? {
        return self.services.first { wrapper in
            wrapper.name == name
        }
    }

    public var statusMessage: String {
        if self.services.isEmpty {
            return "Loading..."
        }

        let statuses = self.services[0...2].map { $0.status }
        if statuses.contains(.loading) {
            return "Determining Valet status..."
        }
        if statuses.contains(.missing) {
            return "A key service is not installed."
        }
        if statuses.contains(.inactive) {
            return "A key service is not running."
        }

        return "All Valet services are OK."
    }

    public var statusColor: Color {
        if self.services.isEmpty {
            return .yellow
        }

        let statuses = self.services[0...2].map { $0.status }
        if statuses.contains(.loading) {
            return .orange
        }
        if statuses.contains(.missing) {
            return .red
        }
        if statuses.contains(.inactive) {
            return .red
        }

        return .green
    }

    @available(*, deprecated, message: "Use a more specific method instead")
    static func loadHomebrewServices() {
        print(self.shared)
        print("This method must be updated")
    }

    public func updateServices() {
        fatalError("Must be implemented in child class")
    }

    var formulae: [HomebrewFormula] {
        var formulae = [
            Homebrew.Formulae.php,
            Homebrew.Formulae.nginx,
            Homebrew.Formulae.dnsmasq
        ]

        let additionalFormulae = (Preferences.custom.services ?? []).map({ item in
            return HomebrewFormula(item, elevated: false)
        })

        formulae.append(contentsOf: additionalFormulae)

        return formulae
    }

    init() {
        Log.info("The services manager will determine which Valet services exist on this system.")

        services = formulae.map {
            ServiceWrapper(formula: $0)
        }
    }
}
