//
//  ShellTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class ShellTest: XCTestCase {
    func test_default_shell_is_system_shell() {
        XCTAssertTrue(Shell is SystemShell)

        XCTAssertTrue(Shell.sync("php -v").output.contains("Copyright (c) The PHP Group"))
    }

    func test_system_shell_has_path() {
        let systemShell = Shell as! SystemShell

        XCTAssertTrue(systemShell.PATH.contains(":/usr/local/bin"))
        XCTAssertTrue(systemShell.PATH.contains(":/usr/bin"))
    }

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

        XCTAssertEqual(expectedPhpOutput, Shell.sync("php -v").output)

        XCTAssertEqual(expectedPhpOutput, Shell.sync("php --version").output)
    }

    func test_unrecognized_commands_output_stderr() {
        ActiveShell.useTestable([:])

        XCTAssertEqual("Unexpected Command", Shell.sync("unrecognized command").output)
    }
}
