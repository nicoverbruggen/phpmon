//
//  CommandTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing

struct CommandTest {
    @Test func determinePhpVersion() {
        let container = Container.real()

        let version = container.command.execute(
            path: container.paths.php,
            arguments: ["-v"],
            trimNewlines: false
        )

        #expect(version.contains("(cli)"))
        #expect(version.contains("NTS"))
        #expect(version.contains("built"))
        #expect(version.contains("Zend"))
    }
}
