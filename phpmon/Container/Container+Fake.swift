//
//  Container+Fake.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Container {
    /**
     Create a new DI `Container` with fake shell responses, filesystem structure and given commands.
     Ideal for testing without a complex TestableConfiguration, so great for unit tests that
     require injecting a new `Container` instance without requiring a complex setup process.
     */
    public static func fake(
        shell: [String: BatchFakeShellOutput] = [:],
        files: [String: FakeFile] = [:],
        commands: [String: String] = [:],
        getResponses: [URL: FakeWebApiResponse] = [:],
        postResponses: [URL: FakeWebApiResponse] = [:]
    ) -> Container {
        // Create a new container
        let container = Container()

        // Fill the container with production (real) components
        container.bind()

        // Replace the key ones with fake ones, so we don't touch the tester's OS, filesystem, etc.
        container.overrideFake(
            shellExpectations: shell,
            fileSystemFiles: files,
            commands: commands,
            webApiGetResponses: getResponses,
            webApiPostResponses: postResponses
        )

        // Return the newly created container
        return container
    }
}
