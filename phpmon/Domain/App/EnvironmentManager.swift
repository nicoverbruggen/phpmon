//
//  EnvironmentManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public class EnvironmentManager {
    var values: [EnvironmentProperty: Bool] = [:]

    public func process() async {
        self.values[.hasValetInstalled] = await !{
            let output = await Shell.pipe("valet --version").out

            // Failure condition #1: does not contain Laravel Valet
            if !output.contains("Laravel Valet") {
                return true
            }

            // Extract the version number
            Valet.shared.version = VersionExtractor.from(output)

            // Get the actual version
            return Valet.shared.version == nil

        }() // returns true if none of the failure conditions are met
    }
}

public enum EnvironmentProperty {
    case hasHomebrewInstalled
    case hasValetInstalled
}
