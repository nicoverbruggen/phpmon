//
//  AppleScript.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

class AppleScript {
    /**
     Execute a simple shell script with administrative privileges (as root).

     @return Returns the output of the script.
     */
    @discardableResult
    public static func runSimpleShellAsAdmin(
        _ script: String
    ) throws -> String {
        let source = "do shell script \"\(script)\" with administrator privileges"
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
            export PATH=/usr/bin:/bin:/usr/sbin:/sbin:\(append) \
            && \(script)
        """
        let source = "do shell script \"\(script)\" with administrator privileges"
        return try runAppleScript(script: source)
    }

    /**
     Runs a given AppleScript.
     */
    private static func runAppleScript(script: String) throws -> String {
        Log.info("Running via AppleScript: `\(script)`")
        let appleScript = NSAppleScript(source: script)

        var error: NSDictionary?
        let eventResult: NSAppleEventDescriptor? = appleScript?.executeAndReturnError(&error)

        if let error = error {
            Log.err("AppleScript error: \(error)")
            throw AdminPrivilegeError(kind: .applescriptNilError)
        }

        guard let result = eventResult else {
            Log.err("Unknown AppleScript error")
            throw AdminPrivilegeError(kind: .applescriptNilError)
        }

        return result.stringValue ?? ""
    }
}
