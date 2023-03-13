//
//  PhpVersionInstaller.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

public class PhpVersionInstaller {
    public static var installables = [
        "8.2": "php",
        "8.1": "php@8.1",
        "8.0": "php@8.0",
        "7.4": "shivammathur/php/php@7.4",
        "7.3": "shivammathur/php/php@7.3",
        "7.2": "shivammathur/php/php@7.2",
        "7.1": "shivammathur/php/php@7.1",
        "7.0": "shivammathur/php/php@7.0"
    ]

    public enum PhpInstallAction {
        case install
        case remove
        case purge
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    public static func modifyPhpVersion(version: String, action: PhpInstallAction) async {
        let title = {
            switch action {
            case .install:
                return "Installing PHP \(version)"
            case .remove:
                return "Removing PHP \(version)"
            case .purge:
                return "Purging PHP \(version)"
            }
        }()

        let description = {
            switch action {
            case .install:
                return "Please wait while Homebrew installs PHP \(version)..."
            case .remove:
                return "Please wait while Homebrew uninstalls PHP \(version)..."
            case .purge:
                return "Please wait while Homebrew purges PHP \(version)"
            }
        }()

        let subject = ProgressViewSubject(
            title: title,
            description: description
        )

        let installables = Self.installables

        if installables.keys.contains(version) {
            let window = await ProgressWindowView.display(subject)
            let formula = installables[version]!

            var command = ""

            if action == .install {
                if formula.contains("shivammathur") && !HomebrewDiagnostics.installedTaps.contains("shivammathur/php") {
                    await Shell.quiet("brew tap shivammathur/php")
                }
            }

            if action == .purge || action == .remove {
                command = "brew remove \(formula) --force --ignore-dependencies"

                if action == .purge {
                    command += " --zap"
                }
            }

            let (process, _) = try! await Shell.attach(
                command,
                didReceiveOutput: { text, _ in
                    if action == .install {
                        // Check if we can recognize any of the typical progress steps
                        if let number = Self.reportInstallationProgress(text) {
                            Task { @MainActor in
                                subject.progress = number
                            }
                        }
                    }
                },
                withTimeout: .minutes(5)
            )

            if process.terminationStatus <= 0 {
                Task { @MainActor in
                    subject.progress = 1
                }

                await PhpEnv.detectPhpVersions()
                await MainMenu.shared.refreshActiveInstallation()
                Task { @MainActor in
                    subject.description = "The operation succeeded. This window will close in 5 seconds."
                }
                await window.close()
            } else {
                // Do not close the window and notify about failure
                Task { @MainActor in
                    subject.description = "The operation failed."
                }
            }
        } else {
            Log.err("\(version) is not contained within installable list")
        }
    }

    public static func installPhpVersion(version: String) async {
        await self.modifyPhpVersion(version: version, action: .install)
    }

    public static func removePhpVersion(version: String) async {
        await self.modifyPhpVersion(version: version, action: .remove)
    }

    private static func reportInstallationProgress(_ text: String) -> Double? {
        if text.contains("Fetching") {
            return 0.1
        }
        if text.contains("Downloading") {
            return 0.25
        }
        if text.contains("Already downloaded") || text.contains("Downloaded") {
            return 0.50
        }
        if text.contains("Installing") {
            return 0.60
        }
        if text.contains("Pouring") {
            return 0.80
        }
        if text.contains("Summary") {
            return 1
        }
        return nil
    }

    /**
     Determine which action will be available in the PHP version manager.
     Some versions will be available to be removed, some to be installed.
     */
    public static var availableActions: [(version: String, action: PhpInstallAction)] {
        var operations: [(version: String, action: PhpInstallAction)] = []

        let installed = PhpEnv.shared.cachedPhpInstallations.keys

        for installable in installables.keys {
            // While technically possible to uninstall the main formula (`php`)
            // this should be disabled in the UI... this data should be correct though
            operations.append((installable, installed.contains(installable) ? .remove : .install))
        }

        operations.sort { $1.version < $0.version }

        return operations
    }

}
