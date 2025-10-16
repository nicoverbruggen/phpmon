//
//  Container+Fake.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

extension Container {
    public func overrideFake(
        shellExpectations: [String: BatchFakeShellOutput] = [:],
        fileSystemFiles: [String: FakeFile] = [:],
        commands: [String: String] = [:]
    ) {
        self.shell = TestableShell(expectations: shellExpectations)
        self.filesystem = TestableFileSystem(files: fileSystemFiles)
        self.command = TestableCommand(commands: commands)
    }

    public static func fake(
        shell: [String: BatchFakeShellOutput] = [:],
        files: [String: FakeFile] = [:],
        commands: [String: String] = [:]
    ) -> Container {
        let container = Container()
        container.prepare()
        container.overrideFake(
            shellExpectations: shell,
            fileSystemFiles: files,
            commands: commands
        )
        return container
    }
}
