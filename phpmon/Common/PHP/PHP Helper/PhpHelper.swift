//
//  PhpHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpHelper {
    static let helperDirectorySuffix = ".config/phpmon/bin"
    static let symlinkDirectory = "/usr/local/bin"

    struct HelperFile {
        let version: String
        let dotless: String
        let destination: String
        let content: String
    }

    @discardableResult
    public static func regenerate(
        _ container: Container,
        installedVersions: Set<String>
    ) async -> [String] {
        let helperDirectoryPath = PhpHelper.helperDirectory(for: container)

        guard PhpHelper.ensureHelperDirectoryExists(container, helperDirectory: helperDirectoryPath) else {
            return []
        }

        let shell = HelperShell.detect(for: container)
        let helperFiles = PhpHelper.makeHelperFiles(shell, container, installedVersions: installedVersions)

        let writtenFiles = PhpHelper.writeHelperFiles(container, files: helperFiles)

        if shouldCreateSymlinks(container, helperDirectory: helperDirectoryPath) {
            await createSymlinks(container, files: helperFiles)
        }

        return writtenFiles
    }
}
