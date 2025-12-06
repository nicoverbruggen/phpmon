//
//  TestableFileSystemTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct TestableFileSystemTest {
    private var container: Container

    init() throws {
        container = Container.fake(files: [
            "/home/user/bin/foo": .fake(.binary),
            "/home/user/docs": .fake(.symlink, "/home/user/documents"),
            "/home/user/documents/script.sh": .fake(.text, "echo 'cool';"),
            "/home/user/documents/nice.txt": .fake(.text, "69"),
            "/home/user/documents/filters/filter1.txt": .fake(.text, "F1"),
            "/home/user/documents/filters/filter2.txt": .fake(.text, "F2")
        ])
    }

    var FileSystem: FileSystemProtocol {
        return container.filesystem
    }

    @Test func testable_fs_is_in_use() {
        #expect(FileSystem is TestableFileSystem)
    }

    @Test func intermediate_directories_are_automatically_created() {
        #expect(FileSystem.directoryExists("/"))
        #expect(FileSystem.directoryExists("/home"))
        #expect(FileSystem.directoryExists("/home/user"))
        #expect(FileSystem.directoryExists("/home/user/documents"))
        #expect(FileSystem.directoryExists("/home/user/bin"))
    }

    @Test func binary_directory_is_writable() {
        #expect(FileSystem.isWriteableFile("/home/user/bin"))
    }

    @Test func binary_exists() {
        #expect(FileSystem.isExecutableFile("/home/user/bin/foo"))
    }

    @Test func can_write_text_to_executable() throws {
        try! FileSystem.writeAtomicallyToFile("/home/user/bin/bar", content: "bar bar bar!")

        #expect(FileSystem.fileExists("/home/user/bin/bar"))
        #expect(!FileSystem.isExecutableFile("/home/user/bin/bar"))

        try! FileSystem.makeExecutable("/home/user/bin/bar")

        #expect(FileSystem.isExecutableFile("/home/user/bin/bar"))
    }

    @Test func can_create_directory() throws {
        try! FileSystem.createDirectory(
            "/home/nico/phpmon/config",
            withIntermediateDirectories: true
        )

        #expect(FileSystem
            .anyExists("/home/nico/phpmon/config"))
        #expect(FileSystem.directoryExists("/home/nico/phpmon/config"))
    }

    @Test func can_create_nested_directories() throws {
        try FileSystem.createDirectory(
            "/home/user/thing/epic/nested/directories",
            withIntermediateDirectories: true
        )

        #expect(FileSystem.directoryExists("/"))
        #expect(FileSystem.directoryExists("/home"))
        #expect(FileSystem.directoryExists("/home/user"))
        #expect(FileSystem.directoryExists("/home/user/thing"))
        #expect(FileSystem.directoryExists("/home/user/thing/epic/nested"))
        #expect(FileSystem.directoryExists("/home/user/thing/epic/nested/directories"))
    }

    @Test func can_list_directory_contents() throws {
        let contents = try! FileSystem.getShallowContentsOfDirectory("/home/user/documents")

        #expect(
            contents.sorted() ==
            [
                "script.sh",
                "nice.txt",
                "filters"
            ].sorted()
        )
    }

    @Test func can_delete_directory_recursively() {
        #expect(FileSystem.directoryExists("/home/user/documents"))
        #expect(FileSystem.directoryExists("/home/user/documents/filters"))
        #expect(FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))

        try! FileSystem.remove("/home/user/documents")

        #expect(!FileSystem.directoryExists("/home/user/documents"))
        #expect(!FileSystem.directoryExists("/home/user/documents/filters"))
        #expect(!FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))
    }

    @Test func can_move_directory() {
        #expect(FileSystem.directoryExists("/home/user/documents"))
        #expect(FileSystem.directoryExists("/home/user/documents/filters"))
        #expect(FileSystem.fileExists("/home/user/documents/filters/filter1.txt"))

        try! FileSystem.move(from: "/home/user/documents", to: "/home/user/new")

        #expect(FileSystem.directoryExists("/home/user/new"))
        #expect(FileSystem.directoryExists("/home/user/new/filters"))
        #expect(FileSystem.fileExists("/home/user/new/filters/filter1.txt"))
    }
}
