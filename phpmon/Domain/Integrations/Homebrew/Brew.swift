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
}
