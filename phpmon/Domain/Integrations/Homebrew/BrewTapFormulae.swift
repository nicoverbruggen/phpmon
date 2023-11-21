//
//  BrewTapFormulae.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class BrewTapFormulae {
    public static func from(tap: String) -> [String: Set<String>] {
        let directory = "\(Paths.tapPath)/\(tap)/Formula"

        let files = try? FileSystem.getShallowContentsOfDirectory(directory)

        var availableExtensions = [String: Set<String>]()

        guard let files else {
            return availableExtensions
        }

        let regex = try! NSRegularExpression(pattern: "(\\w+)@(\\d+\\.\\d+)\\.rb")

        for file in files {
            let matches = regex.matches(in: file, range: NSRange(file.startIndex..., in: file))
            if let match = matches.first {
                if let phpExtensionRange = Range(match.range(at: 1), in: file),
                   let versionRange = Range(match.range(at: 2), in: file) {
                    let phpExtension = String(file[phpExtensionRange])
                    let phpVersion = String(file[versionRange])

                    if var existingExtensions = availableExtensions[phpVersion] {
                        existingExtensions.insert(phpExtension)
                        availableExtensions[phpVersion] = existingExtensions
                    } else {
                        availableExtensions[phpVersion] = [phpExtension]
                    }
                }
            }
        }

        return availableExtensions
    }
}
