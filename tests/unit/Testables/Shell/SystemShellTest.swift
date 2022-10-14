//
//  SystemShellTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 28/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class SystemShellTest: XCTestCase {

    override class func setUp() {
        // Reset to the default shell
        ActiveShell.useSystem()
    }

    func test_system_shell_is_default() async {
        XCTAssertTrue(Shell is RealShell)

        let output = await Shell.pipe("php -v")

        XCTAssertTrue(output.out.contains("Copyright (c) The PHP Group"))
    }

    func test_system_shell_has_path() {
        let systemShell = Shell as! RealShell

        XCTAssertTrue(systemShell.PATH.contains(":/usr/local/bin"))
        XCTAssertTrue(systemShell.PATH.contains(":/usr/bin"))
    }

    func test_system_shell_can_buffer_output() async {
        var bits: [String] = []

        let (_, shellOutput) = try! await Shell.attach(
            "php -r \"echo 'Hello world' . PHP_EOL; usleep(200); echo 'Goodbye world';\"",
            didReceiveOutput: { incoming, _ in
                bits.append(incoming)
            },
            withTimeout: 2.0
        )

        XCTAssertTrue(bits.contains("Hello world\n"))
        XCTAssertTrue(bits.contains("Goodbye world"))
        XCTAssertEqual("Hello world\nGoodbye world", shellOutput.out)
    }

    func test_system_shell_can_timeout_and_throw_error() async {
        let expectation = XCTestExpectation(description: #function)

        do {
            _ = try await Shell.attach(
                "php -r \"sleep(1);\"",
                didReceiveOutput: { _, _ in },
                withTimeout: 0.1
            )
        } catch {
            XCTAssertEqual(error as? ShellError, ShellError.timedOut)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func test_system_processes_run_in_parallel() async {
        let expectation = XCTestExpectation(description: #function)

        let thing = {
            await Shell.quiet("php -r \"usleep(700);\"")
            await Shell.quiet("php -r \"usleep(700);\"")
            await Shell.quiet("php -r \"usleep(700);\"")
            expectation.fulfill()
        }

        await thing()
        wait(for: [expectation], timeout: 1.0)
    }
}
