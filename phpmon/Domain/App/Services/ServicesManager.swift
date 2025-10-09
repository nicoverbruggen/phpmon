//
//  ServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import SwiftUI
import ContainerMacro

@ContainerAccess
class ServicesManager: ObservableObject {

    @ObservedObject static var shared: ServicesManager = ValetServicesManager()

    @Published var services = [Service]()

    @Published var firstRunComplete: Bool = false

    public static func useFake() {
        ServicesManager.shared = FakeServicesManager.init(
            formulae: ["php", "nginx", "dnsmasq", "mysql"],
            status: .active
        )
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
        if self.services.isEmpty || !self.firstRunComplete {
            return false
        }

        return self.services[0...2]
            .map { $0.status }
            .contains(.error)
    }

    public var statusMessage: String {
        if self.services.isEmpty || !self.firstRunComplete {
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
        if self.services.isEmpty || !self.firstRunComplete {
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

    /**
     This method will notify all publishers that subscribe to notifiable objects.
     The notified objects include this very ServicesManager as well as any individual service instances.
     */
    public func broadcastServicesUpdated() {
        Task { @MainActor in
            self.objectWillChange.send()
        }
    }

    var formulae: [HomebrewFormula] {
        var formulae = [
            HomebrewFormulae.php,
            HomebrewFormulae.nginx,
            HomebrewFormulae.dnsmasq
        ]

        let additionalFormulae = (Preferences.custom.services ?? []).map({ item in
            return HomebrewFormula(item, elevated: false)
        })

        formulae.append(contentsOf: additionalFormulae)

        return formulae
    }

    init(container: Container = App.shared.container) {
        Log.info("The services manager will determine which Valet services exist on this system.")

        self.container = container

        services = formulae.map {
            Service(formula: $0)
        }
    }
}
