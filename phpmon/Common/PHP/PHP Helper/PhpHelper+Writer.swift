//
//  PhpHelper+Writer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension PhpHelper {
    static func writeHelperFiles(
        _ container: Container,
        files: [HelperFile]
    ) -> [String] {
        var writtenFiles: [String] = []

        for file in files {
            do {
                if try writeIfNeeded(container, file: file) {
                    writtenFiles.append(file.destination)
                }
            } catch {
                Log.err(error)
                Log.err("Could not write PHP Monitor helper for PHP \(file.version) to \(file.destination).")
            }
        }

        return writtenFiles
    }

    private static func writeIfNeeded(
        _ container: Container,
        file: HelperFile
    ) throws -> Bool {
        let existingContents = container.filesystem.fileExists(file.destination)
            ? try? container.filesystem.getStringFromFile(file.destination)
            : nil

        if existingContents != file.content {
            try container.filesystem.writeAtomicallyToFile(file.destination, content: file.content)
        }

        if !container.filesystem.isExecutableFile(file.destination) {
            try container.filesystem.makeExecutable(file.destination)
        }

        return existingContents != file.content
    }
}
