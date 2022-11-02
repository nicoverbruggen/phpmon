//
//  RealFileSystemTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 02/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class RealFileSystemTest: XCTestCase {

    override class func setUp() {
        ActiveFileSystem.useSystem()
    }

    func test_testable_fs_is_in_use() {
        XCTAssertTrue(FileSystem is RealFileSystem)
    }

}
