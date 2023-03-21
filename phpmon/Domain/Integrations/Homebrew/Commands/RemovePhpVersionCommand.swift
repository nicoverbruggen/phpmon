//
//  RemovePhpVersionCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class RemovePhpVersionCommand: BrewCommand {
    let formula: String
    let version: String

    init(formula: String) {
        self.version = formula
            .replacingOccurrences(of: "php@", with: "")
            .replacingOccurrences(of: "shivammathur/php/", with: "")
        self.formula = formula
    }

    func execute(onProgress: @escaping (BrewCommandProgress) -> Void) async throws {
        let progressTitle = "Removing PHP \(version)..."

        onProgress(.create(
            value: 0.2,
            title: progressTitle,
            description: "Please wait while Homebrew removes PHP \(version)..."
        ))

        let command = """
            export HOMEBREW_NO_INSTALL_UPGRADE=true; \
            export HOMEBREW_NO_INSTALL_CLEANUP=true; \
            \(Paths.brew) remove \(formula) --force --ignore-dependencies
            """

        do {
            try await self.fixPermissions(for: formula)
        } catch {
            return
        }

        let (process, _) = try! await Shell.attach(
            command,
            didReceiveOutput: { text, _ in
                if !text.isEmpty {
                    Log.perf(text)
                }
            },
            withTimeout: .minutes(5)
        )

        if process.terminationStatus <= 0 {
            onProgress(.create(value: 0.95, title: progressTitle, description: "Reloading PHP versions..."))
            await PhpEnv.detectPhpVersions()
            await MainMenu.shared.refreshActiveInstallation()
            onProgress(.create(value: 1, title: progressTitle, description: "The operation has succeeded."))
        } else {
            throw BrewCommandError(error: "The command failed to run correctly.")
        }
    }

    /**
     Takes ownership of the /BREW_PATH/Cellar/php/x.y.z/bin folder (if required).

     This might not be required if the user has only used that version of PHP
     with site isolation, so this method checks if it's required first.
     */
    private func fixPermissions(for formula: String) async throws {
        // Omit the prefix
        let path = formula.replacingOccurrences(of: "shivammathur/php/", with: "")

        // Binary path needs to be checked for ownership
        let binaryPath = "\(Paths.optPath)/\(path)/bin"

        // Check if it's even necessary to perform the fix
        if !isOwnedByRoot(path: binaryPath) {
            return
        }

        Log.info("Need to take ownership of `\(binaryPath)`...")

        let script = """
            \(Paths.brew) services stop \(formula) \
            && chown -R \(Paths.whoami):admin \(Paths.cellarPath)/\(path)
            """

        let appleScript = NSAppleScript(
            source: "do shell script \"\(script)\" with administrator privileges"
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
    private func isOwnedByRoot(path: String) -> Bool {
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
}
