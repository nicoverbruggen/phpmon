//
//  TestableFileSystemTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

class TestableFileSystemTest: XCTestCase {

    override func setUp() async throws {
        ActiveFileSystem.useTestable([
            "/home/user/bin/foo": .fake(.binary),
            "/home/user/docs": .fake(.symlink, "/home/user/documents"),
            "/home/user/documents/script.sh": .fake(.text, "echo 'cool';"),
            "/home/user/documents/nice.txt": .fake(.text, "69"),
            "/home/user/documents/filters/filter1.txt": .fake(.text, "F1"),
            "/home/user/documents/filters/filter2.txt": .fake(.text, "F2")
        ])
    }

    func test_testable_fs_is_in_use() {
        XCTAssertTrue(FileSystem is TestableFileSystem)
    }

    func test_intermediate_directories_are_automatically_created() {
        XCTAssertTrue(FileSystem.directoryExists("/"))
        XCTAssertTrue(FileSystem.directoryExists("/home"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/documents"))
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

        XCTAssertTrue(FileSystem
            .anyExists("/home/nico/phpmon/config"))
        XCTAssertTrue(FileSystem.directoryExists("/home/nico/phpmon/config"))
    }

    func test_can_create_nested_directories() throws {
        try FileSystem.createDirectory(
            "/home/user/thing/epic/nested/directories",
            withIntermediateDirectories: true
        )

        XCTAssertTrue(FileSystem.directoryExists("/"))
        XCTAssertTrue(FileSystem.directoryExists("/home"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/thing"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/thing/epic/nested"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/thing/epic/nested/directories"))
    }

    func test_can_list_directory_contents() throws {
        let contents = try! FileSystem.getShallowContentsOfDirectory("/home/user/documents")

        XCTAssertEqual(
            contents.sorted(),
            [
                "script.sh",
                "nice.txt",
                "filters"
            ].sorted()
        )
    }

    func test_can_delete_directory_recursively() {
        XCTAssertTrue(FileSystem.directoryExists("/home/user/documents"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/documents/filters"))
        XCTAssertTrue(FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))

        try! FileSystem.remove("/home/user/documents")

        XCTAssertFalse(FileSystem.directoryExists("/home/user/documents"))
        XCTAssertFalse(FileSystem.directoryExists("/home/user/documents/filters"))
        XCTAssertFalse(FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))
    }

    func test_can_move_directory() {
        XCTAssertTrue(FileSystem.directoryExists("/home/user/documents"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/documents/filters"))
        XCTAssertTrue(FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))

        try! FileSystem.move(from: "/home/user/documents", to: "/home/user/new")

        XCTAssertTrue(FileSystem.directoryExists("/home/user/new"))
        XCTAssertTrue(FileSystem.directoryExists("/home/user/new/filters"))
        XCTAssertTrue(FileSystem.fileExists("/home/user/new/filters/filter1.txt"))
    }
}
