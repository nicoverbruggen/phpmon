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
            let path = URL(fileURLWithPath: "\(container.paths.optPath)/php@\(version)/bin")
                .resolvingSymlinksInPath().path

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
}
