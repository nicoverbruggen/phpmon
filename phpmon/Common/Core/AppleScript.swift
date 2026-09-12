//
//  AppleScript.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

// `nonisolated`: these calls block until the user has dealt with the password
// prompt and the elevated command has finished, so they must be callable off
// the main actor (wrapped in `runBlocking` at the call sites). This is why the
// script runs through an `osascript` subprocess rather than `NSAppleScript`,
// which is documented as main-thread-only.
nonisolated class AppleScript {
    /**
     Execute a simple shell script with administrative privileges (as root).

     @return Returns the output of the script.
     */
    @discardableResult
    public static func runSimpleShellAsAdmin(
        _ script: String
    ) throws -> String {
        let source = "do shell script \"\(escape(script))\" with administrator privileges"
        return try runAppleScript(script: source)
    }

    /**
     Execute a shell script with administrative privileges, but sets USER to the current user, and also adds the Homebrew `bin` folder to the PATH.

     Using this may be necessary for certain scripts to work correctly, like `valet trust`, which may execute `which php` as part of the PHP script it runs, and thus requires knowledge about the current user and where the PHP binaries are.

     @return The output of the script.
     */
    @discardableResult
    public static func runShellAsAdmin(
        _ script: String,
        asUser user: String = App.shared.container.paths.whoami,
        appendToPATH append: String = App.shared.container.paths.binPath,
    ) throws -> String {
        let script = """
            export USER=\(user) && \
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:\(append) && \
            \(script)
        """
        let source = "do shell script \"\(escape(script))\" with administrator privileges"
        return try runAppleScript(script: source)
    }

    private static func escape(_ value: String) -> String {
        return value
            .replacing("\\", with: "\\\\")
            .replacing("\"", with: "\\\"")
    }

    /**
     Runs a given AppleScript via `/usr/bin/osascript`.

     A subprocess is used instead of `NSAppleScript` because the latter is
     documented as main-thread-only, and these scripts (admin prompts plus the
     elevated command itself) can block for a long time — they need to be able
     to run on the concurrent pool. The subprocess shows the exact same
     administrator-privileges prompt.
     */
    private static func runAppleScript(script: String) throws -> String {
        Log.info("Running via AppleScript: `\(script)`")

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        do {
            try task.run()
        } catch {
            Log.err("osascript could not be launched: \(error)")
            throw AdminPrivilegeError(kind: .applescriptNilError)
        }

        let captured = RealShell.getOutput(stdout: outputPipe, stderr: errorPipe)
        task.waitUntilExit()

        let output = captured.out
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let errorOutput = captured.err
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if task.terminationStatus != 0 {
            Log.err("AppleScript error: \(errorOutput)")

            // Error -128 means the user dismissed the password prompt.
            if errorOutput.contains("(-128)") {
                throw AdminPrivilegeError(kind: .userDenied)
            }

            throw AdminPrivilegeError(kind: .applescriptNilError)
        }

        return output
    }
}
