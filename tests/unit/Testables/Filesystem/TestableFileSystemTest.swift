//
//  TestableFileSystemTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class TestableFileSystemTest: XCTestCase {

    override class func setUp() {
        ActiveFileSystem.useTestable([
            "/home/user/bin": .fake(.directory),
            "/home/user/bin/foo": .fake(.binary),
            "/home/user/documents": .fake(.directory),
            "/home/user/docs": .fake(.symlink, "/home/user/documents"),
            "/home/user/documents/nice.txt": .fake(.text, "69"),
            "/home/user/documents/script.sh": .fake(.text, "echo 'cool';")
        ])
    }

    func test_testable_fs_is_in_use() {
        XCTAssertTrue(FileSystem is TestableFileSystem)
    }

    func test_binary_directory_exists() {
        XCTAssertTrue(FileSystem.directoryExists("/home/user/bin"))
    }

    func test_binary_directory_is_writable() {
        XCTAssertTrue(FileSystem.isWriteableFile("/home/user/bin"))
    }

    func test_binary_exists() {
        XCTAssertTrue(FileSystem.isExecutableFile("/home/user/bin/foo"))
    }

    func test_can_write_text_to_executable() throws {
        try! FileSystem.writeAtomicallyToFile("/home/user/bin/bar", content: "bar bar bar!")

        XCTAssertFalse(FileSystem.isExecutableFile("/home/user/bin/bar"))

        try! FileSystem.makeExecutable("/home/user/bin/bar")

        XCTAssertTrue(FileSystem.isExecutableFile("/home/user/bin/bar"))
    }

    func test_can_create_directory() throws {
        try! FileSystem.createDirectory(
            "/home/nico/phpmon/config",
            withIntermediateDirectories: true
        )

        XCTAssertTrue(FileSystem.anyExists("/home/nico/phpmon/config"))
        XCTAssertTrue(FileSystem.directoryExists("/home/nico/phpmon/config"))
    }

    // TODO: Implement and test the remove() and move() methods and reorganize method order
}
