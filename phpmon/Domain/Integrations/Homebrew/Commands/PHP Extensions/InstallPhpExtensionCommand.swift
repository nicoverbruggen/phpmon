//
//  InstallPhpExtensionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class InstallPhpExtensionCommand: BrewCommand {
    let installing: [BrewPhpExtension]

    func getExtensionNames() -> String {
        return installing.map { $0.name }.joined(separator: ", ")
    }

    func getCommandTitle() -> String {
        return "phpman.steps.installing".localized(getExtensionNames())
    }

    public init(install extensions: [BrewPhpExtension]) {
        self.installing = extensions
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "phpman.steps.wait".localized

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "phpman.steps.preparing".localized
        ))

        // Make sure the tap is installed
        try await self.checkPhpTap(onProgress)

        // Make sure that the extension(s) are installed
        try await self.installPackages(onProgress)

        // Finally, complete all operations
        await self.completedOperations(onProgress)
    }

    private func installPackages(_ onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        // If no installations are needed, early exit
        if self.installing.isEmpty {
            return
        }

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) install \(self.installing.map { $0.formulaName }.joined(separator: " ")) --force
            """

        try await run(command, onProgress)
    }

    private func completedOperations(_ onProgress: @escaping (BrewCommandProgress) -> Void) async {
        // Reload and restart PHP versions
        onProgress(.create(value: 0.95, title: self.getCommandTitle(), description: "phpman.steps.reloading".localized))

        // Restart PHP-FPM
        if let installed = self.installing.first {
            await Actions.restartPhpFpm(version: installed.phpVersion)
        }

        // Check which version of PHP are now installed
        await PhpEnvironments.detectPhpVersions()

        // Keep track of the currently installed version
        await MainMenu.shared.refreshActiveInstallation()

        // Also rebuild the content of the main menu
        await MainMenu.shared.rebuild()

        // Let the UI know that the installation has been completed
        onProgress(.create(
            value: 1,
            title: "phpman.steps.completed".localized,
            description: "phpman.steps.success".localized
        ))
    }

}
