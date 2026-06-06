//
//  PhpHelper+Paths.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension PhpHelper {
    static func helperDirectory(for container: Container) -> String {
        return "\(container.paths.homePath)/\(helperDirectorySuffix)"
    }

    static func helperDestination(for container: Container, dotless: String) -> String {
        return "\(helperDirectory(for: container))/pm\(dotless)"
    }

    static func ensureHelperDirectoryExists(
        _ container: Container,
        helperDirectory: String
    ) -> Bool {
        do {
            if !container.filesystem.directoryExists(helperDirectory) {
                try container.filesystem.createDirectory(
                    helperDirectory,
                    withIntermediateDirectories: true
                )
            }

            return true
        } catch {
            Log.err(error)
            Log.err("Could not create the PHP Monitor helper directory at \(helperDirectory).")
            return false
        }
    }
}
