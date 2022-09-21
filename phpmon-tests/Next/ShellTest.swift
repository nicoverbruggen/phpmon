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
        XCTAssertTrue(NxtShell.shared is SystemShell)

        XCTAssertTrue(NxtShell.shared.syncPipe("php -v")
            .contains("Copyright (c) The PHP Group"))
    }

    func test_we_can_predefine_responses_for_dummy_shell() {
        let expectedPhpOutput = """
                PHP 8.1.10 (cli) (built: Sep  3 2022 12:09:27) (NTS)
                Copyright (c) The PHP Group
                Zend Engine v4.1.10, Copyright (c) Zend Technologies
                with Zend OPcache v8.1.10, Copyright (c), by Zend Technologies
                with Xdebug v3.1.4, Copyright (c) 2002-2022, by Derick Rethans
            """

        NxtShell.useTestable([
            "php -v": expectedPhpOutput
        ])

        XCTAssertTrue(NxtShell.shared is TestableShell)

        XCTAssertEqual(expectedPhpOutput, NxtShell.shared.syncPipe("php -v"))
    }
}
