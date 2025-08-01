//
//  Provision.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

class Provision {
    /**
     Adds a given line to .zshrc, which may be needed to adjust the PATH.
     */
    private func addToShell(_ text: String) async -> Bool {
        let outcome = await Shell.pipe("""
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
     Installs Homebrew. Requires elevated permission.
     */
    public func installHomebrew() async throws {
        let script = """
            NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """

        _ = try await Shell.attach(script, didReceiveOutput: { (string: String, _: ShellStream) in
            print(string)
        }, withTimeout: 60 * 10)
    }

    /**
     Adds Homebrew binaries to the PATH.
     */
    public func addHomebrewPath() async {
        _ = await addToShell("export PATH=$HOME/bin:/opt/homebrew/bin:$PATH")
    }

    /**
     Adds Homebrew binaries to the PATH.
     */
    public func addPhpMonitorPath() async {
        _ = await addToShell("export PATH=$HOME/bin:~/.config/phpmon/bin:$PATH")
    }
}
