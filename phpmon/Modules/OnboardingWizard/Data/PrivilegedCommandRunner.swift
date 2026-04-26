//
//  PrivilegedCommandRunner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

struct PrivilegedCommandRunner {
    private let runCommand: @Sendable (String) throws -> String

    init(
        _ runCommand: @Sendable @escaping (String) throws -> String
    ) {
        self.runCommand = runCommand
    }

    init(container: Container) {
        if App.hasLoadedTestableConfiguration || container.shell is TestableShell {
            self.init { command in
                let output = container.shell.sync(command)

                if output.hasError {
                    throw NSError(
                        domain: "phpmon.onboarding",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: output.err]
                    )
                }

                return output.out
            }
            return
        }

        self.init { command in
            try AppleScript.runShellAsAdmin(command)
        }
    }

    func run(_ command: String) throws -> String {
        try runCommand(command)
    }
}
