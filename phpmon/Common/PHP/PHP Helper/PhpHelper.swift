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

        // Determine what shell the user is using (supported: zsh, bash, fish)
        let shell = HelperShell.detect(for: container)

        // Prepare the helper files for the detected shell
        let helperFiles = PhpHelper.makeHelperFiles(shell, container, installedVersions: installedVersions)

        // Writes the helper files (but only if the files are changed!)
        let writtenFiles = PhpHelper.writeHelperFiles(container, files: helperFiles)

        // If the helper directory is in the PATH, the symlinks won't be created
        if shouldCreateSymlinks(container, helperDirectory: helperDirectoryPath) {
            await createSymlinks(container, files: helperFiles)
        }

        // Return the list of updated helper files
        return writtenFiles
    }
}
