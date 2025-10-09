//
//  Provision+zshrc.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import ContainerMacro

@ContainerAccess
class ZshRunCommand {
    /**
     Adds a given line to .zshrc, which may be needed to adjust the PATH.
     */
    private func add(_ text: String) async -> Bool {
        let outcome = await shell.pipe("""
            touch ~/.zshrc && \
            grep -qxF '\(text)' ~/.zshrc \
            || echo '\n\n\(text)\n' >> ~/.zshrc
        """)

        if outcome.hasError {
            return false
        }

        return true
    }

    /**
     Adds Homebrew binaries to the PATH.
     */
    public func addHomebrewPath() async {
        _ = await add("export PATH=$HOME/bin:/opt/homebrew/bin:$PATH")
    }

    /**
     Adds PHP Monitor binaries to the PATH.
     */
    public func addPhpMonitorPath() async {
        _ = await add("export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH")
    }
}
