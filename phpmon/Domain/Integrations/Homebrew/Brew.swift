//
//  Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class Brew {
    static let shared = Brew()

    /// The version of Homebrew that was detected.
    var version: VersionNumber?

    public func determineVersion() async {
        let output = await Shell.pipe("\(Paths.brew) --version")
        self.version = try? VersionNumber.parse(output.out)

        if let version = version {
            Log.info("The user has Homebrew \(version.text) installed.")

            if version.major < 4 {
                Log.warn("Managing PHP versions is only supported with Homebrew 4 or newer!")
            }
        } else {
            Log.warn("The Homebrew version could not be determined.")
        }
    }

    public func getPhpVersions() async -> [BrewFormula] {
        let command = """
        \(Paths.brew) update >/dev/null && \
        \(Paths.brew) outdated --json --formulae
        """

        let raw = await Shell.pipe(command).out
        print(raw)

        // We can now figure out what updates there are

        // We also know what's installed
        let items = PhpEnv.shared.cachedPhpInstallations.keys
        print(items)

        return []
    }
}
