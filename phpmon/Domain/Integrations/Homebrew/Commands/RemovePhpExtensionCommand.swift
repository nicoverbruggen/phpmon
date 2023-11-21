//
//  RemovePhpExtensionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/11/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class RemovePhpExtensionCommand: BrewCommand {
    public let phpExtension: BrewPhpExtension

    public init(remove formula: BrewPhpExtension) {
        self.phpExtension = formula
    }

    func getCommandTitle() -> String {
        return "phpman.steps.removing".localized(phpExtension.name)
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        onProgress(.create(
            value: 0.2,
            title: getCommandTitle(),
            description: "phpman.steps.removing".localized("`\(phpExtension.name)`...")
        ))

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) remove \(phpExtension.formulaName) --force --ignore-dependencies
            """

        var loggedMessages: [String] = []

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                    loggedMessages.append(text)
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus <= 0 {
            onProgress(.create(value: 0.95, title: getCommandTitle(), description: "phpman.steps.reloading".localized))

            await PhpEnvironments.detectPhpVersions()

            await MainMenu.shared.refreshActiveInstallation()

            onProgress(.create(value: 1, title: getCommandTitle(), description: "phpman.steps.success".localized))
        } else {
            throw BrewCommandError(error: "phpman.steps.failure".localized, log: loggedMessages)
        }
    }
}
