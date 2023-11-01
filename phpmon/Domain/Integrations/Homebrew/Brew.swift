//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewFormulaeObservable: ObservableObject {
    @Published var phpVersions: [BrewPhpFormula] = []

    var upgradeable: [BrewPhpFormula] {
        return phpVersions.filter { formula in
            formula.hasUpgrade
        }
    }
}

class Brew {
    static let shared = Brew()

    /// Formulae that can be observed.
    var formulae = BrewFormulaeObservable()

    /// The version of Homebrew that was detected.
    var version: VersionNumber?

    /// Determine which version of Homebrew is installed.
    public func determineVersion() async {
        let output = await Shell.pipe("\(Paths.brew) --version")
        self.version = try? VersionNumber.parse(output.out)

        if let version = version {
            Log.info("The user has Homebrew \(version.text) installed.")

            if version.major < 4 {
                Log.warn("Managing PHP versions is only officially supported with Homebrew 4 or newer!")
            }
        } else {
            Log.warn("The Homebrew version could not be determined.")
        }
    }

    /// Each formula for each PHP version that can be installed.
    public static let phpVersionFormulae = [
        "8.4": "shivammathur/php/php@8.4",
        "8.3": "shivammathur/php/php@8.3", // TODO: when php@8.3 lands in stable, update this
        "8.2": "php@8.2",
        "8.1": "php@8.1",
        "8.0": "php@8.0",
        "7.4": "shivammathur/php/php@7.4",
        "7.3": "shivammathur/php/php@7.3",
        "7.2": "shivammathur/php/php@7.2",
        "7.1": "shivammathur/php/php@7.1",
        "7.0": "shivammathur/php/php@7.0",
        "5.6": "shivammathur/php/php@5.6"
    ]
}
