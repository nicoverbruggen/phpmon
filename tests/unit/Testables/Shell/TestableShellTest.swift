//
//  TestableShellTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite(.serialized)
struct TestableShellTest {
    @Test func fake_shell_output_can_be_declared() async {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(0.3, "Goodbye world")
        ])

        let output = await greeting.outputInstantaneously()

        #expect("Hello world\nGoodbye world" == output.out)
    }

    @Test func fake_shell_can_output_in_realtime() async {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(2, "Goodbye world")
        ])

        let output = await greeting.output(didReceiveOutput: { _, _ in })

        #expect("Hello world\nGoodbye world" == output.out)
    }

    @Test func fake_shell_synchronous_output() {
        let greeting = BatchFakeShellOutput(items: [
            .instant("Hello world\n"),
            .delayed(0.2, "Goodbye world")
        ])

        let output = greeting.syncOutput()

        #expect("Hello world\nGoodbye world" == output.out)
    }

    @Test func fake_shell_usage() {
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

        #expect(expectedOutput == shell.sync("php -v").out)
        #expect("/Users/user/bin:/opt/homebrew/bin" == shell.sync("echo $PATH").out)
    }

    @Test func fake_shell_has_path() {
        let container = Container.fake()

        #expect(container.shell.PATH == "/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin")
    }
}
