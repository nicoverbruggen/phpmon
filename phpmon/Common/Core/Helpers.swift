//
//  Helpers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

// MARK: Common Shell Commands

/**
 Runs a `valet` command. Defaults to running as superuser.
 */
func valet(_ command: String, sudo: Bool = true) -> String
{
    return Shell.pipe("\(sudo ? "sudo " : "")" + "\(Paths.valet) \(command)", requiresPath: true)
}

/**
 Runs a `brew` command. Can run as superuser.
 */
func brew(_ command: String, sudo: Bool = false)
{
    Shell.run("\(sudo ? "sudo " : "")" + "\(Paths.brew) \(command)")
}

/**
 Runs `sed` in order to replace all occurrences of a string in a specific file with another.
 */
func sed(file: String, original: String, replacement: String)
{
    // Escape slashes (or `sed` won't work)
    let e_original = original.replacingOccurrences(of: "/", with: "\\/")
    let e_replacement = replacement.replacingOccurrences(of: "/", with: "\\/")
    
    // Check if gsed exists; it is able to follow symlinks,
    // which we want to do to toggle the extension
    if Shell.fileExists("\(Paths.binPath)/gsed") {
        Shell.run("\(Paths.binPath)/gsed -i --follow-symlinks 's/\(e_original)/\(e_replacement)/g' \(file)")
    } else {
        Shell.run("sed -i '' 's/\(e_original)/\(e_replacement)/g' \(file)")
    }
}

/**
 Uses `grep` to determine whether a particular query string can be found in a particular file.
 */
func grepContains(file: String, query: String) -> Bool
{
    return Shell.pipe("""
            grep -q '\(query)' \(file); [ $? -eq 0 ] && echo "YES" || echo "NO"
            """)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .contains("YES")
}
