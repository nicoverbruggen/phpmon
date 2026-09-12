//
//  PhpHelper.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpHelper {
    // `nonisolated`: immutable constants read by the nonisolated writer/symlink helpers.
    nonisolated static let helperDirectorySuffix = ".config/phpmon/bin"
    nonisolated static let symlinkDirectory = "/usr/local/bin"

    // `nonisolated` + `Sendable`: helper files are written to disk on the
    // concurrent pool (blocking I/O), so these values cross isolation boundaries.
    nonisolated struct HelperFile: Sendable {
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
        // Blocking file I/O, so this hops to the concurrent pool.
        let writtenFiles = await runBlocking { PhpHelper.writeHelperFiles(container, files: helperFiles) }

        // If the helper directory is in the PATH, the symlinks won't be created
        if await runBlocking({ shouldCreateSymlinks(container, helperDirectory: helperDirectoryPath) }) {
            await createSymlinks(container, files: helperFiles)
        }

        // Return the list of updated helper files
        return writtenFiles
    }
}
