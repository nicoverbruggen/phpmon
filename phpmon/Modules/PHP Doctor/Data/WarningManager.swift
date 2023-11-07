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

    /// These warnings are the ones that are ready to be displayed.
    @Published public var warnings: [Warning] = []

    /// This variable is thread-safe and may be modified at any time.
    /// When all temporary warnings are set, you may broadcast these changes
    /// and they will be sent to the @Published variable via the main thread.
    private var temporaryWarnings: [Warning] = []

    init() {
        if isRunningSwiftUIPreview {
            /// SwiftUI previews will always list all possible evaluations.
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
            title: "warnings.arm_compatibility.title",
            paragraphs: { return ["warnings.arm_compatibility.description"] },
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-and-Apple-Silicon"
        ),
        Warning(
            command: {
                return !Shell.PATH.contains("\(Paths.homePath)/.config/phpmon/bin") &&
                    !FileSystem.isWriteableFile("/usr/local/bin/")
            },
            name: "Helpers cannot be symlinked and not in PATH",
            title: "warnings.helper_permissions.title",
            paragraphs: { return [
                "warnings.helper_permissions.description",
                "warnings.helper_permissions.unavailable",
                "warnings.helper_permissions.symlink"
            ] },
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries"
        ),
        Warning(
            command: {
                PhpConfigChecker.shared.check()
                return !PhpConfigChecker.shared.missing.isEmpty
            },
            name: "Your PHP installation is missing configuration files",
            title: "warnings.files_missing.title",
            paragraphs: { return [
                "warnings.files_missing.description".localized(
                    PhpConfigChecker.shared.missing.joined(separator: "\n• ")
                )
            ] },
            url: nil
        )
    ]

    public func hasWarnings() -> Bool {
        return !warnings.isEmpty
    }

    func evaluateWarnings() {
        Task { await WarningManager.shared.checkEnvironment() }
    }

    @MainActor func clearWarnings() {
        self.warnings = []
    }

    @MainActor func broadcastWarnings() {
        self.warnings = temporaryWarnings
    }

    /**
     Checks the user's environment and checks if any special warnings apply.
     */
    func checkEnvironment() async {
        if ProcessInfo.processInfo.environment["EXTREME_DOCTOR_MODE"] != nil {
            self.temporaryWarnings = self.evaluations
            await self.broadcastWarnings()
            return
        }

        await evaluate()
        await MainMenu.shared.rebuild()
    }

    /**
     Runs through all evaluations and appends any applicable warning results.
     Will automatically broadcast these warnings.
     */
    private func evaluate() async {
        self.temporaryWarnings = []

        for check in self.evaluations where await check.applies() {
            Log.info("[DOCTOR] \(check.name) (!)")
            self.temporaryWarnings.append(check)
            continue
        }

        await self.broadcastWarnings()
    }
}
