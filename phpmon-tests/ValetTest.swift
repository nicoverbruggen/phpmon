//
//  ValetTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import XCTest

class ValetTest: XCTestCase {

    func testDetermineValetVersion() {
        let version = valet("--version")
        XCTAssert(version.contains("Laravel Valet 2."))
    }
    
}
