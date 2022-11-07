//
//  FeatureTestCase.swift
//  Feature Tests
//
//  Created by Nico Verbruggen on 07/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class FeatureTestCase: XCTestCase {

    var fakeFileSystem: TestableFileSystem {
        let fs = ActiveFileSystem.shared

        if fs is TestableFileSystem {
            return fs as! TestableFileSystem
        }

        fatalError("The active filesystem is not a TestableFileSystem. Please use `ActiveFileSystem` to use the fake filesystem.")
    }

    public func assertFileSystemHas(
        _ path: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(fakeFileSystem.files.keys.contains(path), file: file, line: line)
    }

    public func assertFileSystemDoesNotHave(
        _ path: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(fakeFileSystem.files.keys.contains(path), file: file, line: line)
    }

    public func assertFileHasContents(
        _ path: String,
        contents: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(contents, fakeFileSystem.files[path]?.content, file: file, line: line)
    }

}

