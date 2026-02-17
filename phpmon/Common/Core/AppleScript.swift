//
//  AppleScript.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 17/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 Execute a script with administrative privileges.
 Returns the output of the script.
 */
@discardableResult
func sudo(_ script: String) throws -> String {
    let source = "do shell script \"\(script)\" with administrator privileges"

    Log.info("Running script via AppleScript as administrator: `\(source)`")

    let appleScript = NSAppleScript(source: source)

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
