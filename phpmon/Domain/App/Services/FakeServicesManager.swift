//
//  FakeServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeServicesManager: ServicesManager {
    var fixedFormulae: [String] = []
    var fixedStatus: Service.Status = .active

    override init() {}

    init(
        formulae: [String] = ["php", "nginx", "dnsmasq"],
        status: Service.Status = .active
    ) {
        super.init()

        Log.warn("A fake services manager is being used, so Homebrew formula resolver is set to act in fake mode.")
        Log.warn("If you do not want this behaviour, do not make use of a `FakeServicesManager`!")

        self.fixedFormulae = formulae
        self.fixedStatus = status

        self.services = []
        self.reapplyServices()

        self.firstRunComplete = true
    }

    private func reapplyServices() {
        let services = self.formulae.map {
            let wrapper = Service(
                formula: $0,
                service: HomebrewService.dummy(named: $0.name, enabled: self.fixedStatus == .active)
            )
            return wrapper
        }

        Task { @MainActor in
            self.services = services
        }
    }

    override var formulae: [HomebrewFormula] {
        return fixedFormulae.map { formula in
            return HomebrewFormula.init(formula, elevated: false)
        }
    }

    override func reloadServicesStatus() async {
        await delay(seconds: 0.3)

        self.reapplyServices()
    }

    override func toggleService(named: String) async {
        await delay(seconds: 0.3)

        let services = services.map({ service in
            let newServiceEnabled = service.name == named
            ? service.status != .active // inverse (i.e. if active -> becomes inactive)
            : service.status == .active // service remains unmodified if it's not the named one we change

            return Service(
                formula: service.formula,
                service: HomebrewService.dummy(
                    named: service.name,
                    enabled: newServiceEnabled
                )
            )
        })

        Task { @MainActor in
            self.services = services
        }
    }
}
