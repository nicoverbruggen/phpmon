//
//  WarningManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class WarningManager: ObservableObject {

    static var shared: WarningManager = WarningManager()

    init() {
        if isRunningSwiftUIPreview {
            self.warnings = self.evaluations
        }
    }

    public let evaluations: [Warning] = [
        Warning(
            command: {
                return await Shell.pipe("sysctl -n sysctl.proc_translated").out
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "1"
            },
            name: "Running PHP Monitor with Rosetta on M1",
            title: "warnings.arm_compatibility.title".localized,
            paragraphs: { return ["warnings.arm_compatibility.description".localized] },
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-and-Apple-Silicon"
        ),
        Warning(
            command: {
                return !Shell.PATH.contains("\(Paths.homePath)/.config/phpmon/bin") &&
                    !FileSystem.isWriteableFile("/usr/local/bin/")
            },
            name: "Helpers cannot be symlinked and not in PATH",
            title: "warnings.helper_permissions.title".localized,
            paragraphs: { return [
                "warnings.helper_permissions.description".localized,
                "warnings.helper_permissions.unavailable".localized,
                "warnings.helper_permissions.symlink".localized
            ] },
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries"
        ),
        Warning(
            command: {
                PhpConfigChecker.shared.check()
                return !PhpConfigChecker.shared.missing.isEmpty
            },
            name: "Your PHP installation is missing configuration files",
            title: "warnings.files_missing.title".localized,
            paragraphs: { return [
                "warnings.files_missing.description".localized(
                    PhpConfigChecker.shared.missing.joined(separator: "\n• ")
                )
            ] },
            url: nil
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
        if ProcessInfo.processInfo.environment["EXTREME_DOCTOR_MODE"] != nil {
            // For debugging purposes, we may wish to see all possible evaluations listed
            Task { @MainActor in
                self.warnings = self.evaluations
            }
        } else {
            // Otherwise, loop over the actual evaluations and list the warnings
            await loopOverEvaluations()
        }

        await MainMenu.shared.rebuild()
    }

    private func loopOverEvaluations() async {
        Task { @MainActor in
            self.warnings = []
        }
        for check in self.evaluations where await check.applies() {
            Log.info("[DOCTOR] \(check.name) (!)")
            Task { @MainActor in
                self.warnings.append(check)
            }
            continue
        }
    }
}
