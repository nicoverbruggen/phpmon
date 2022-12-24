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
    var fixedStatus: ServiceStatus = .loading

    override init() {}

    init(
        formulae: [String] = ["php", "nginx", "dnsmasq"],
        status: ServiceStatus = .loading
    ) {
        super.init()

        Log.warn("A fake services manager is being used, so Homebrew formula resolver is set to act in fake mode.")
        Log.warn("If you do not want this behaviour, never instantiate FakeServicesManager!")

        self.fixedFormulae = formulae
        self.fixedStatus = status

        self.services = self.formulae.map {
            let wrapper = ServiceWrapper(formula: $0)
            wrapper.service = HomebrewService.dummy(named: $0.name, enabled: true)
            return wrapper
        }
    }

    override var formulae: [HomebrewFormula] {
        return fixedFormulae.map { formula in
            return HomebrewFormula.init(formula, elevated: false)
        }
    }
}
