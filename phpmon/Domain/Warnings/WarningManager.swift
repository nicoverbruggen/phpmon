//
//  WarningManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class WarningManager {

    static var shared = WarningManager()

    init() {
        if isRunningSwiftUIPreview {
            self.warnings = self.evaluations
        }
    }

    public let evaluations: [Warning] = [
        Warning(
            command: {
                return Shell.pipe("sysctl -n sysctl.proc_translated")
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "1"
            },
            name: "Running PHP Monitor with Rosetta on M1",
            title: "warnings.arm_compatibility.title",
            paragraphs: ["warnings.arm_compatibility.description"],
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-and-Apple-Silicon"
        ),
        Warning(
            command: {
                return !Shell.user.PATH.contains("/Users/\(Paths.whoami)/.config/phpmon/bin") &&
                    !FileManager.default.isWritableFile(atPath: "/usr/local/bin/")
            },
            name: "Helpers cannot be symlinked and not in PATH",
            title: "warnings.helper_permissions.title",
            paragraphs: [
                "warnings.helper_permissions.description",
                "warnings.helper_permissions.unavailable",
                "warnings.helper_permissions.symlink"
            ],
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries"
        )
    ]

    @Published public var warnings: [Warning] = []

    public func hasWarnings() -> Bool {
        return !warnings.isEmpty
    }

    func evaluateWarnings() {
        Task { await WarningManager.shared.checkEnvironment() }
    }

    /**
     Checks the user's environment and checks if any special warnings apply.
     */
    func checkEnvironment() async {
        self.warnings = []

        if ProcessInfo.processInfo.environment["EXTREME_DOCTOR_MODE"] != nil {
            // For debugging purposes, we may wish to see all possible evaluations listed
            self.warnings = self.evaluations
        } else {
            // Otherwise, loop over the actual evaluations and list the warnings
            await loopOverEvaluations()
        }

        MainMenu.shared.rebuild()
    }

    private func loopOverEvaluations() async {
        for check in self.evaluations where await check.applies() {
            Log.info("[DOCTOR] \(check.name) (!)")
            self.warnings.append(check)
            continue
        }
    }
}
