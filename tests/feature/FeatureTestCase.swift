//
//  FeatureTestCase.swift
//  Feature Tests
//
//  Created by Nico Verbruggen on 07/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class FeatureTestCase: XCTestCase {
    public func assertFileSystemHas(
        _ path: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        in fs: TestableFileSystem
    ) {
        XCTAssertTrue(fs.files.keys.contains(path), file: file, line: line)
    }

    public func assertFileSystemDoesNotHave(
        _ path: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        in fs: TestableFileSystem
    ) {
        XCTAssertFalse(fs.files.keys.contains(path), file: file, line: line)
    }

    public func assertFileHasContents(
        _ path: String,
        contents: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        in fs: TestableFileSystem
    ) {
        XCTAssertEqual(contents, fs.files[path]?.content, file: file, line: line)
    }
}
