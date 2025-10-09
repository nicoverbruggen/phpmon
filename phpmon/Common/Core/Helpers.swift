//
//  Helpers.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

// MARK: Common Shell Commands

import Foundation

/**
 Runs a `brew` command. Can run as superuser.
 */
func brew(_ command: String, sudo: Bool = false, shell: ShellProtocol = App.shared.container.shell) async {
    await shell.quiet("\(sudo ? "sudo " : "")" + "\(Paths.brew) \(command)")
}

/**
 Runs `sed` in order to replace all occurrences of a string in a specific file with another.
 */
func sed(
    file: String,
    original: String,
    replacement: String,
    filesystem: FileSystemProtocol = App.shared.container.filesystem,
    shell: ShellProtocol = App.shared.container.shell
) async {
    // Escape slashes (or `sed` won't work)
    let e_original = original.replacingOccurrences(of: "/", with: "\\/")
    let e_replacement = replacement.replacingOccurrences(of: "/", with: "\\/")

    // Check if gsed exists; it is able to follow symlinks,
    // which we want to do to toggle the extension
    if filesystem.fileExists("\(Paths.binPath)/gsed") {
        await shell.quiet("\(Paths.binPath)/gsed -i --follow-symlinks 's/\(e_original)/\(e_replacement)/g' \(file)")
    } else {
        await shell.quiet("sed -i '' 's/\(e_original)/\(e_replacement)/g' \(file)")
    }
}

/**
 Uses `grep` to determine whether a particular query string can be found in a particular file.
 */
func grepContains(file: String, query: String, shell: ShellProtocol = App.shared.container.shell) async -> Bool {
    return await shell.pipe("""
            grep -q '\(query)' \(file); [ $? -eq 0 ] && echo "YES" || echo "NO"
            """).out
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .contains("YES")
}

/**
 Attempts to introduce sleep for a particular duration. Use with caution.
 */
func delay(seconds: Double) async {
    try! await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
}

/**
 A simpler way to initialize a fixed, valid URL.
 */
func url(_ string: String) -> URL {
    return URL(string: string)!
}
