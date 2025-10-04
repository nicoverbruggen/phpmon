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
            name: "Running PHP Monitor with Rosetta on Apple Silicon",
            title: "warnings.arm_compatibility.title",
            paragraphs: { return ["warnings.arm_compatibility.description"] },
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-and-Apple-Silicon",
            fix: nil
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
            url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries",
            fix: Paths.shell == "/bin/zsh" ? {
                // Add to PATH
                await ZshRunCommand().addPhpMonitorPath()
                // Finally, perform environment checks again
                await WarningManager.shared.checkEnvironment()
            } : nil
        ),
        Warning(
            command: {
                PhpEnvironments.shared.currentInstall?.extensions.contains { $0.name == "xdebug" } ?? false
                && !Xdebug.enabled
            },
            name: "Missing configuration file for `xdebug.mode`",
            title: "warnings.xdebug_conf_missing.title",
            paragraphs: { return [
                "warnings.xdebug_conf_missing.description"
            ] },
            url: "https://xdebug.org/docs/install#mode",
            fix: {
                if let php = PhpEnvironments.shared.currentInstall {
                    if let xdebug = php.extensions.first(where: { $0.name == "xdebug" }),
                       let original = try? FileSystem.getStringFromFile(xdebug.file) {
                        // Append xdebug.mode = off to the file
                        try? FileSystem.writeAtomicallyToFile(
                            xdebug.file,
                            content: original + "\nxdebug.mode = off"
                        )

                        // Reload extension configuration by updating PHP installation info (reload)
                        PhpEnvironments.shared.currentInstall = ActivePhpInstallation()

                        // Finally, reload warnings
                        await WarningManager.shared.checkEnvironment()
                    }
                }
            }
        ),
        Warning(
            command: {
                !BrewDiagnostics.installedTaps.contains("shivammathur/php")
            },
            name: "`shivammathur/php` tap is missing",
            title: "warnings.php_tap_missing.title",
            paragraphs: { return [
                "warnings.php_tap_missing.description"
            ] },
            url: "https://github.com/shivammathur/homebrew-php",
            fix: {
                await Shell.quiet("brew tap shivammathur/php")
                await BrewDiagnostics.loadInstalledTaps()
                await WarningManager.shared.checkEnvironment()
            }
        ),
        Warning(
            command: {
                !BrewDiagnostics.installedTaps.contains("shivammathur/extensions")
            },
            name: "`shivammathur/extensions` tap is missing",
            title: "warnings.extensions_tap_missing.title",
            paragraphs: { return [
                "warnings.extensions_tap_missing.description"
            ] },
            url: "https://github.com/shivammathur/homebrew-extensions",
            fix: {
                await Shell.quiet("brew tap shivammathur/extensions")
                await BrewDiagnostics.loadInstalledTaps()
                await WarningManager.shared.checkEnvironment()
            }
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
            url: nil,
            fix: nil
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
        ActiveShell.reload()

        await BrewDiagnostics.loadInstalledTaps()

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
