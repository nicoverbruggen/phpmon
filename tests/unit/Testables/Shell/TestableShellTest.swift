//
//  TestableShellTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class TestableShellTest: XCTestCase {
    func test_fake_shell_output_can_be_declared() async {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(0.3, "Goodbye world")
        ])

        let output = await greeting.outputInstantaneously()

        XCTAssertEqual("Hello world\nGoodbye world", output.out)
    }

    func test_fake_shell_can_output_in_realtime() async {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(2, "Goodbye world")
        ])

        let output = await greeting.output(didReceiveOutput: { _, _ in })

        XCTAssertEqual("Hello world\nGoodbye world", output.out)
    }
    
    func test_fake_shell_synchronous_output() {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(0.2, "Goodbye world")
        ])

        let output = greeting.syncOutput()

        XCTAssertEqual("Hello world\nGoodbye world", output.out)
    }

    func test_fake_shell_usage() {
        let expectedOutput = """
                PHP 8.3.0 (cli) (built: Nov 21 2023 14:40:35) (NTS)
                Copyright (c) The PHP Group
                Zend Engine v4.3.0, Copyright (c) Zend Technologies
                with Xdebug v3.2.2, Copyright (c) 2002-2023, by Derick Rethans
                with Zend OPcache v8.3.0, Copyright (c), by Zend Technologies
                """

        let shell = TestableShell(expectations: [
            "php -v": .instant(expectedOutput),
            "echo $PATH": .instant("/Users/user/bin:/opt/homebrew/bin")
        ])

        XCTAssertEqual(expectedOutput, shell.sync("php -v").out)
        XCTAssertEqual("/Users/user/bin:/opt/homebrew/bin", shell.sync("echo $PATH").out)
    }

    func test_fake_shell_has_path() {
        ActiveShell.useTestable([:])

        XCTAssertEqual(Shell.PATH, "/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin")
    }
}
