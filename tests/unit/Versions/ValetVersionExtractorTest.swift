//
//  ValetTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class ValetVersionExtractorTest: XCTestCase {

    func testDetermineValetVersion() async {
        let version = await valet("--version", sudo: false)
        XCTAssert(version.contains("Laravel Valet 2") || version.contains("Laravel Valet 3"))
    }

}
