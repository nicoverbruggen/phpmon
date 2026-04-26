//
//  Provision+zshrc.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class ZshRunCommand {

    // MARK: - Container

    var container: Container

    init(_ container: Container) {
        self.container = container
    }

    // MARK: - Methods

    /**
     Adds a given line to .zshrc, which may be needed to adjust the PATH.
     */
    @discardableResult
    private func add(_ text: String) async -> Bool {
        if zshrcAlreadyContainsLine(for: text) {
            return true
        }

        // Escape single quotes to prevent shell injection
        let escaped = text.replacingOccurrences(of: "'", with: "'\\''")

        // Actually add the line to .zshrc
        let outcome = await container.shell.pipe("""
            touch ~/.zshrc && \
            grep -qxF '\(escaped)' ~/.zshrc \
            || printf '%s\\n' '\(escaped)' >> ~/.zshrc
        """)

        // Validate the command executed correctly
        if outcome.hasError {
            return false
        }

        return true
    }

    private func zshrcAlreadyContainsLine(for text: String) -> Bool {
        guard container.filesystem.fileExists("~/.zshrc"),
              let contents = try? container.filesystem.getStringFromFile("~/.zshrc") else {
            return false
        }

        let path = text
            .replacingOccurrences(of: "export PATH=$HOME/bin:", with: "")
            .replacingOccurrences(of: ":$PATH", with: "")

        return pathEntries(in: contents).contains(
            PathEntry.normalize(path, homePath: container.paths.homePath)
        )
    }

    /**
     Extracts path-like tokens from `.zshrc` so we can detect equivalent entries even when
     they are written differently from the exact export line we generate.

     This intentionally recognizes paths that start with `/`, `~/`, or `$HOME/`, then relies
     on `PathEntry.normalize(...)` to collapse those spellings into a single comparable form.
     */
    private func pathEntries(in contents: String) -> Set<String> {
        let regex = try? NSRegularExpression(pattern: #"(?:(?:\$HOME|~|/)[^:\s"'()]+)"#)
        let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)

        let entries = regex?.matches(in: contents, range: range).compactMap { match -> String? in
            guard let range = Range(match.range, in: contents) else {
                return nil
            }

            return PathEntry.normalize(String(contents[range]), homePath: container.paths.homePath)
        } ?? []

        return Set(entries)
    }

    /**
     Adds Homebrew binaries to the PATH.
     */
    @discardableResult
    public func addHomebrewBinPath() async -> Bool {
        await add(ShellEnvironment(container).homebrewBinPathExport)
    }

    /**
     Adds Composer's global vendor binaries to the PATH.
     */
    @discardableResult
    public func addComposerBinPath() async -> Bool {
        await add(ShellEnvironment(container).composerBinPathExport)
    }

    /**
     Adds PHP Monitor binaries to the PATH.
     */
    @discardableResult
    public func addPhpMonitorBinPath() async -> Bool {
        await add(ShellEnvironment(container).phpMonitorBinPathExport)
    }
}
