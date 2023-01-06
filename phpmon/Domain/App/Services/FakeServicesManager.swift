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
    var fixedStatus: ServiceStatus = .active

    override init() {}

    init(
        formulae: [String] = ["php", "nginx", "dnsmasq"],
        status: ServiceStatus = .active
    ) {
        super.init()

        Log.warn("A fake services manager is being used, so Homebrew formula resolver is set to act in fake mode.")
        Log.warn("If you do not want this behaviour, do not make use of a `FakeServicesManager`!")

        self.fixedFormulae = formulae
        self.fixedStatus = status

        self.serviceWrappers = self.formulae.map {
            let wrapper = ServiceWrapper(
                formula: $0,
                service: HomebrewService.dummy(named: $0.name, enabled: true)
            )
            return wrapper
        }
    }

    override var formulae: [HomebrewFormula] {
        return fixedFormulae.map { formula in
            return HomebrewFormula.init(formula, elevated: false)
        }
    }

    override func reloadServicesStatus() async {
        await delay(seconds: 0.3)
    }

    override func toggleService(named: String) async {
        await delay(seconds: 0.3)
    }
}
