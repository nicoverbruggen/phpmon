//
//  ServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI

class ServicesManager: ObservableObject {

    var container: Container
    let registry: ServicesRegistry

    static var shared: ServicesManager = {
        let registry = ServicesRegistry(App.shared.container)
        return ValetServicesManager(App.shared.container, registry: registry)
    }()

    @Published var services = [Service]()

    init(_ container: Container, registry: ServicesRegistry) {
        self.container = container
        self.registry = registry

        Log.info("The services manager will determine which Valet services exist on this system.")
        services = formulae.map {
            Service(formula: $0)
        }
    }

    public static func useFake(_ container: Container) {
        ServicesManager.shared = FakeServicesManager.init(
            container,
            registry: ServicesRegistry(container),
            formulae: ["php", "nginx", "dnsmasq", "mysql"],
            status: .active
        )
    }

    var formulae: [HomebrewFormula] {
        registry.formulae
    }

    /**
     The order of services is important, so easy access is accomplished
     without much fanfare through subscripting.
     */
    subscript(name: String) -> Service? {
        return self.services.first { wrapper in
            wrapper.name == name
        }
    }

    public var hasError: Bool {
        if self.services.isEmpty {
            return false
        }

        return self.services[0...2]
            .map { $0.status }
            .contains(.error)
    }

    public var statusMessage: String {
        if self.services.isEmpty {
            return "phpman.services.loading".localized
        }

        let statuses = self.services[0...2].map { $0.status }

        if statuses.contains(.missing) {
            return "phpman.services.not_installed".localized
        }
        if statuses.contains(.error) {
            return "phpman.services.error".localized
        }
        if statuses.contains(.inactive) {
            return "phpman.services.inactive".localized
        }

        return "phpman.services.all_ok".localized
    }

    public var statusColor: Color {
        if self.services.isEmpty {
            return Color("StatusColorYellow")
        }

        let statuses = self.services[0...2].map { $0.status }

        if statuses.contains(.missing)
            || statuses.contains(.inactive)
            || statuses.contains(.error) {
            return Color("StatusColorRed")
        }

        return Color("StatusColorGreen")
    }

    /**
     This method is called when the system configuration has changed
     and all the status of one or more services may need to be determined.
     */
    public func reloadServicesStatus() async {
        fatalError("This method `\(#function)` has not been implemented")
    }

    /**
     This method is called when a service needs to be toggled (on/off).
     */
    public func toggleService(named: String) async {
        fatalError("This method `\(#function)` has not been implemented")
    }
}
