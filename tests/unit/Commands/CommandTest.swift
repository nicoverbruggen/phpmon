//
//  CommandTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 13/02/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class CommandTest: XCTestCase {

    func testDeterminePhpVersion() {
        let version = Command.execute(
            path: Paths.php,
            arguments: ["-v"],
            trimNewlines: false
        )

        XCTAssert(version.contains("(cli)"))
        XCTAssert(version.contains("NTS"))
        XCTAssert(version.contains("built"))
        XCTAssert(version.contains("Zend"))
    }

}
