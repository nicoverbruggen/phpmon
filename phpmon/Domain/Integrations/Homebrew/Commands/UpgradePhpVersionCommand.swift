//
//  InstallPhpVersionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

public typealias BrewDependent = String

class UpgradePhpVersionCommand: BrewCommand {
    let formula: String
    let version: String

    init(formula: String) {
        self.version = formula
            .replacingOccurrences(of: "php@", with: "")
            .replacingOccurrences(of: "shivammathur/php/", with: "")
        self.formula = formula
    }

    func execute() async throws -> [BrewDependent] {
        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) upgrade \(formula) -n
        """

        // Use this command to do a dry-run of the upgrade
        // This will let us figure out the impact or failure modes
        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                }
            },
            withTimeout: .minutes(5)
        )

        return []
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        //
    }
}
