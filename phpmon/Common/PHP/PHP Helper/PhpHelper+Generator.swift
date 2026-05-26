//
//  PhpHelper+Generator.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension PhpHelper {
    static func makeHelperFiles(
        _ shell: HelperShell,
        _ container: Container,
        installedVersions: Set<String>
    ) -> [HelperFile] {
        return Constants.DetectedPhpVersions
            .sorted(by: { $0.versionCompare($1) == .orderedDescending })
            .map { version in
                makeHelperFile(
                    shell,
                    container,
                    version: version,
                    installed: installedVersions.contains(version)
                )
            }
    }

    private static func makeHelperFile(
        _ shell: HelperShell,
        _ container: Container,
        version: String,
        installed: Bool
    ) -> HelperFile {
        let dotless = version.replacing(".", with: "")
        let destination = helperDestination(for: container, dotless: dotless)

        let content: String
        if installed {
            let path = resolvedPhpBinaryDirectory(container, version: version)

            content = shell.installedScript(container, path: path, version: version, dotless: dotless)
        } else {
            content = shell.unavailableScript(container, version: version)
        }

        return HelperFile(
            version: version,
            dotless: dotless,
            destination: destination,
            content: content
        )
    }

    /**
     Resolve Homebrew's `opt` symlink through the container filesystem, so both
     fake filesystem tests and the actual host filesystem resolve PHP binary
     paths through the same abstraction.
     */
    private static func resolvedPhpBinaryDirectory(_ container: Container, version: String) -> String {
        let optFormulaPath = "\(container.paths.optPath)/php@\(version)"
        let resolvedFormulaPath = resolvedSymlink(optFormulaPath, using: container) ?? optFormulaPath

        return "\(resolvedFormulaPath)/bin"
    }

    private static func resolvedSymlink(_ symlinkPath: String, using container: Container) -> String? {
        // Ask the active filesystem for the symlink target.
        guard let destination = try? container.filesystem.getDestinationOfSymlink(symlinkPath) else {
            // Return nil when the path is not a readable symlink.
            return nil
        }

        // Example: `/opt/homebrew/opt/php@8.4` may point to `../Cellar/php@8.4/8.4.0`.
        // Use the symlink's parent (`/opt/homebrew/opt`) as the base for that relative target.
        let parent = URL(fileURLWithPath: symlinkPath).deletingLastPathComponent()

        // Normalize the resolved destination and return it as a plain filesystem path.
        return URL(fileURLWithPath: destination, relativeTo: parent).standardizedFileURL.path
    }
}
