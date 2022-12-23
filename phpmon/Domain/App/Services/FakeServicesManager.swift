//
//  FakeServicesManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeServicesManager: ServicesManager {
    override init() {
        Log.warn("A fake services manager is being used, so Homebrew formula resolver is set to act in fake mode.")
        Log.warn("If you do not want this behaviour, never instantiate FakeServicesManager!")
        Homebrew.fake = true
    }

    override var formulae: [HomebrewFormula] {
        var formulae = [
            Homebrew.Formulae.php,
            Homebrew.Formulae.nginx,
            Homebrew.Formulae.dnsmasq
        ]

        let additionalFormulae = ["mailhog", "coolio"].map({ name in
            return HomebrewFormula(name, elevated: false)
        })

        formulae.append(contentsOf: additionalFormulae)

        return formulae
    }
}
