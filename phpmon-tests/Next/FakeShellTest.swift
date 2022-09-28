//
//  ShellTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class FakeShellTest: XCTestCase {
    func test_we_can_predefine_responses_for_dummy_shell() {
        let expectedPhpOutput = """
                PHP 8.1.10 (cli) (built: Sep  3 2022 12:09:27) (NTS)
                Copyright (c) The PHP Group
                Zend Engine v4.1.10, Copyright (c) Zend Technologies
                with Zend OPcache v8.1.10, Copyright (c), by Zend Technologies
                with Xdebug v3.1.4, Copyright (c) 2002-2022, by Derick Rethans
            """

        let slowVersionOutput = FakeTerminalOutput(
            output: expectedPhpOutput,
            duration: 1000,
            isError: false
        )

        ActiveShell.useTestable([
            "php -v": expectedPhpOutput,
            "php --version": slowVersionOutput
        ])

        XCTAssertTrue(Shell is TestableShell)

        XCTAssertEqual(expectedPhpOutput, Shell.sync("php -v").out)

        XCTAssertEqual(expectedPhpOutput, Shell.sync("php --version").out)
    }

    func test_unrecognized_commands_output_stderr() {
        ActiveShell.useTestable([:])

        let output = Shell.sync("unrecognized command")

        XCTAssertTrue(output.hasError)
        XCTAssertEqual("Unexpected Command", output.err)
        XCTAssertEqual("", output.out)
    }
}
