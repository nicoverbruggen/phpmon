//
//  InstallHomebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import ContainerMacro

@ContainerAccess
class InstallHomebrew {
    public func run() async throws {
        let script = """
            NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """

        _ = try await container.shell.attach(script, didReceiveOutput: { (string: String, _: ShellStream) in
            print(string)
        }, withTimeout: 60 * 10)
    }

    public func verify() async {
        // Make sure the Homebrew directory exists
        // Make sure the `brew` binary exists
    }
}
