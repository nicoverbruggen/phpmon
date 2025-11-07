//
//  Container+Fake.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

extension Container {
    /**
     Manually specify what overrides need to be active for the container.
     */
    private func overrideFake(
        shellExpectations: [String: BatchFakeShellOutput] = [:],
        fileSystemFiles: [String: FakeFile] = [:],
        commands: [String: String] = [:]
    ) {
        self.shell = TestableShell(expectations: shellExpectations)
        self.filesystem = TestableFileSystem(files: fileSystemFiles)
        self.command = TestableCommand(commands: commands)
    }

    /**
     Use a `TestableConfiguration` as the basis for shell, filesystem and more.
     This is used for testing scenarios to avoid needing to have a specific system configuration.
     Ideal for feature or UI tests, where a complete "computer configuration" needs to be mimicked.
     */
    public func overrideWith(config: TestableConfiguration) {
        self.overrideFake(
            shellExpectations: config.shellOutput,
            fileSystemFiles: config.filesystem,
            commands: config.commandOutput
        )
    }

    /**
     Create a new DI `Container` with fake shell responses, filesystem structure and given commands.
     Ideal for testing without a complex TestableConfiguration, so great for unit tests that
     require injecting a new `Container` instance without requiring a complex setup process.
     */
    public static func fake(
        shell: [String: BatchFakeShellOutput] = [:],
        files: [String: FakeFile] = [:],
        commands: [String: String] = [:]
    ) -> Container {
        // Create a new container
        let container = Container()

        // Fill the container with production (real) components
        container.prepare()

        // Replace the key ones with fake ones, so we don't touch the tester's OS, filesystem, etc.
        container.overrideFake(
            shellExpectations: shell,
            fileSystemFiles: files,
            commands: commands
        )

        // Return the newly created container
        return container
    }
}
