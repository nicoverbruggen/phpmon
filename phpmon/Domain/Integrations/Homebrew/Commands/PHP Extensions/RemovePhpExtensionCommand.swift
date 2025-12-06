//
//  RemovePhpExtensionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class RemovePhpExtensionCommand: BrewCommand {

    // MARK: - Container

    var container: Container

    // MARK: - Variables

    public let phpExtension: BrewPhpExtension

    // MARK: - Methods

    public init(_ container: Container,
                remove formula: BrewPhpExtension) {
        self.container = container
        self.phpExtension = formula
    }

    func getCommandTitle() -> String {
        return "phpman.steps.removing".localized(phpExtension.name)
    }

    func execute(shell: ShellProtocol, onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        onProgress(.create(
            value: 0.2,
            title: getCommandTitle(),
            description: "phpman.steps.removing".localized("`\(phpExtension.name)`...")
        ))

        // Keep track of the file that contains the information about the extension
        let existing = container.phpEnvs
            .cachedPhpInstallations[phpExtension.phpVersion]?
            .extensions.first(where: { ext in
            ext.name == phpExtension.name
        })

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            export HOMEBREW_DOWNLOAD_CONCURRENCY=auto; \
            \(container.paths.brew) remove \(phpExtension.formulaName) --force --ignore-dependencies
            """

        var loggedMessages: [String] = []

        let (process, _) = try! await shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus == 0 {
            onProgress(.create(value: 0.95, title: getCommandTitle(), description: "phpman.steps.reloading".localized))

            if let ext = existing {
                await performExtensionCleanup(for: ext)
            }

            _ = await container.phpEnvs.detectPhpVersions()

            await Actions(container).restartPhpFpm(version: phpExtension.phpVersion)

            await MainMenu.shared.refreshActiveInstallation()

            onProgress(.create(value: 1, title: getCommandTitle(), description: "phpman.steps.success".localized))
        } else {
            throw BrewCommandError(error: "phpman.steps.failure".localized, log: loggedMessages)
        }
    }

    private func performExtensionCleanup(for ext: PhpExtension) async {
        if ext.file.hasSuffix("20-\(ext.name).ini") {
            // The extension's default configuration file can be removed
            Log.info("The extension was found in a default extension .ini location. Purging that .ini file.")
            do {
                try container.filesystem.remove(ext.file)
            } catch {
                Log.err("The file `\(ext.file)` could not be removed.")
            }
        } else {
            // The extension's default configuration file cannot be removed, it should be disabled instead
            Log.info("The extension was not found in a default location. Disabling the extension only.")
            if ext.enabled {
                await ext.toggle()
            }
        }
    }
}
