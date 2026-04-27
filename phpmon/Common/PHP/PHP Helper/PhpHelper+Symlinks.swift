//
//  PhpHelper+Symlinks.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension PhpHelper {
    static func shouldCreateSymlinks(
        _ container: Container,
        helperDirectory: String
    ) -> Bool {
        if container.shell.PATH.contains(helperDirectory) {
            return false
        }

        if !container.filesystem.isWriteableFile("\(symlinkDirectory)/") {
            Log.err("PHP Monitor does not have permission to symlink helpers in `\(symlinkDirectory)`.")
            return false
        }

        return true
    }

    static func createSymlinks(
        _ container: Container,
        files: [HelperFile]
    ) async {
        for file in files {
            await createSymlink(container, dotless: file.dotless)
        }
    }

    private static func createSymlink(
        _ container: Container,
        dotless: String
    ) async {
        let source = helperDestination(for: container, dotless: dotless)
        let destination = "\(symlinkDirectory)/pm\(dotless)"

        if !container.filesystem.fileExists(destination) {
            Log.info("Creating new symlink: \(destination)")
            await container.shell.pipe("ln -s \(source) \(destination)")
            return
        }

        if !container.filesystem.isSymlink(destination) {
            Log.info("Overwriting existing file with new symlink: \(destination)")
            await container.shell.pipe("ln -fs \(source) \(destination)")
            return
        }

        Log.info("Symlink in \(destination) already exists, OK.")
    }
}
