//
//  PhpVersionInstaller.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

public class PhpVersionInstaller {
    public static var installables = [
        // "8.2": "php",
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
    /**
     Performs the desired action on the provided PHP version.
     */
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
            let windowController = await ProgressWindowView.display(subject)
            await NSApp.activate(ignoringOtherApps: true)
            await windowController.window?.makeKeyAndOrderFront(nil)

            let formula = installables[version]!

            var command: String!

            if action == .install {
                if formula.contains("shivammathur") && !HomebrewDiagnostics.installedTaps.contains("shivammathur/php") {
                    await Shell.quiet("brew tap shivammathur/php")
                }

                command = """
                export HOMEBREW_NO_INSTALL_UPGRADE=1 \
                && export HOMEBREW_NO_INSTALL_CLEANUP=1 \
                && brew install \(formula) --force
                """
            }

            // TODO: Ensure that a PHP version can also be updated
            /*
            if action == .update {

            }
            */

            if action == .purge || action == .remove {
                // Removal always requires permission
                do {
                    try await PhpVersionInstaller.fixPermissions(for: formula)
                } catch {
                    Task { @MainActor in
                        subject.progress = 1
                        subject.title = "Could not take permission of required folder"
                        subject.description = "Please try again!"
                    }
                    return
                }

                // Actually do the removal
                command = "brew remove \(formula) --force --ignore-dependencies"

                // Check if the permissions are correct; if not, fix permissions
                if action == .purge {
                    command += " --zap"
                }
            }

            let (process, _) = try! await Shell.attach(
                command,
                didReceiveOutput: { text, _ in
                    if action == .install {
                        if !text.isEmpty {
                            Log.perf(text)
                        }

                        // Check if we can recognize any of the typical progress steps
                        if let (number, text) = Self.reportInstallationProgress(text) {
                            Task { @MainActor in
                                subject.progress = number
                                subject.description = text
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
                    windowController.close()
                }
            } else {
                // Do not close the window and notify about failure
                Task { @MainActor in
                    subject.title = "Operation failed: something went wrong"
                    subject.progress = 1
                    subject.description = "Oops. You may close this window."
                }
            }
        } else {
            Log.err("\(version) is not contained within installable list")
        }
    }

    /** Installs a given PHP version. Never requires administrative privileges. */
    public static func installPhpVersion(version: String) async {
        await self.modifyPhpVersion(version: version, action: .install)
    }

    /** Uninstalls a given PHP version. Might require administrative privileges. */
    public static func removePhpVersion(version: String) async {
        await self.modifyPhpVersion(version: version, action: .remove)
    }

    /**
     Takes ownership of the /BREW_PATH/Cellar/php/x.y.z/bin folder (if required).

     This might not be required if the user has only used that version of PHP
     with site isolation, so this method checks if it's required first.
     */
    public static func fixPermissions(for formula: String) async throws {
        // Omit the prefix
        let path = formula.replacingOccurrences(of: "shivammathur/php/", with: "")

        // Binary path needs to be checked for ownership
        let binaryPath = "\(Paths.optPath)/\(path)/bin"

        // Check if it's even necessary to perform the fix
        if !isOwnedByRoot(path: binaryPath) {
            return
        }

        Log.info("The ownership of the folder at `\(binaryPath)` is currently not correct. Will prompt to take ownership!")

        let script = """
            \(Paths.brew) services stop \(formula) \
            && chown -R \(Paths.whoami):admin \(Paths.cellarPath)/\(path)
            """

        let appleScript = NSAppleScript(source:
            "do shell script \"\(script)\" with administrator privileges"
        )

        let eventResult: NSAppleEventDescriptor? = appleScript?.executeAndReturnError(nil)

        if eventResult == nil {
            throw HomebrewPermissionError(kind: .applescriptNilError)
        }

        Log.info("Ownership was taken of the folder at `\(binaryPath)`.")
    }

    /**
     Checks if a given path is owned by root. If so, ownership might need to be taken.
     */
    private static func isOwnedByRoot(path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let owner = attributes[.ownerAccountName] as? String {
                return owner == "root"
            }
        } catch {
            return true
        }

        return true
    }

    private static func reportInstallationProgress(_ text: String) -> (Double, String)? {
        if text.contains("Fetching") {
            return (0.1, "Fetching...")
        }
        if text.contains("Downloading") {
            return (0.25, "Downloading...")
        }
        if text.contains("Already downloaded") || text.contains("Downloaded") {
            return (0.50, "Downloaded!")
        }
        if text.contains("Installing") {
            return (0.60, "Installing...")
        }
        if text.contains("Pouring") {
            return (0.80, "Pouring... this can take a while!")
        }
        if text.contains("Summary") {
            return (1, "The installation is done!")
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
        let unsupported = PhpEnv.shared.incompatiblePhpVersions

        for installable in installables.keys {
            // While technically possible to uninstall the main formula (`php`)
            // this should be disabled in the UI... this data should be correct though
            let availableOperation: PhpInstallAction =
                installed.contains(installable) || unsupported.contains(installable) ? .remove : .install

            operations.append((version: installable, action: availableOperation))
        }

        operations.sort { $1.version < $0.version }

        return operations
    }

}
