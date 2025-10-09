//
//  RealFileSystemTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 02/11/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

@Suite(.serialized)
struct RealFileSystemTest {
    var filesystem: FileSystemProtocol

    init() throws {
        let container = Container()
        container.prepare()

        filesystem = container.filesystem
    }

    private func createUniqueTemporaryDirectory() -> String {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let fullTempDirectoryPath = tempDirectoryURL.appendingPathComponent("phpmon-fs-tests").path
        try? FileManager.default.removeItem(atPath: fullTempDirectoryPath)
        try! FileManager.default.createDirectory(atPath: fullTempDirectoryPath, withIntermediateDirectories: false)
        return fullTempDirectoryPath
    }

    private func createTestBinaryFile(_ temporaryDirectory: String) -> String {
        let executablePath = "\(temporaryDirectory)/exec.sh"

        try! filesystem.writeAtomicallyToFile(executablePath, content: """
            !#/bin/bash
            echo 'Hello world';
            """)

        return executablePath
    }

    @Test func testable_fs_is_in_use() {
        #expect(filesystem is RealFileSystem)
    }

    @Test func temporary_path_exists() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        // True
        #expect(filesystem.directoryExists(temporaryDirectory))
        #expect(filesystem.anyExists(temporaryDirectory))

        // False
        #expect(!filesystem.fileExists(temporaryDirectory))
    }

    @Test func directory_can_be_created_symlinked_and_read() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        let folderPath = "\(temporaryDirectory)/brew/etc/lib/c"

        try! filesystem.createDirectory(folderPath, withIntermediateDirectories: true)

        #expect(filesystem.directoryExists("\(temporaryDirectory)/brew"))
        #expect(filesystem.directoryExists("\(temporaryDirectory)/brew/etc"))
        #expect(filesystem.directoryExists("\(temporaryDirectory)/brew/etc/lib"))
        #expect(filesystem.directoryExists("\(temporaryDirectory)/brew/etc/lib/c"))

        _ = system("ln -s \(temporaryDirectory)/brew/etc/lib/c \(temporaryDirectory)/c")
        #expect(filesystem.directoryExists("\(temporaryDirectory)/c"))
        #expect(filesystem.isSymlink("\(temporaryDirectory)/c"))
        #expect(
            try! filesystem.getDestinationOfSymlink("\(temporaryDirectory)/c") ==
            "\(temporaryDirectory)/brew/etc/lib/c"
        )

        let contents = try! FileSystem.getShallowContentsOfDirectory("\(temporaryDirectory)/brew/etc/lib/c")
        #expect([] == contents)
    }

    @Test func can_read_file_as_text() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(
            try! filesystem.getStringFromFile(executable) ==
            """
            !#/bin/bash
            echo 'Hello world';
            """
        )
    }

    @Test func make_binary_executable() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(filesystem.isWriteableFile(executable))
        #expect(!filesystem.isExecutableFile(executable))

        try! filesystem.makeExecutable(executable)

        #expect(filesystem.isExecutableFile(executable))
        #expect(!filesystem.isDirectory(executable))
        #expect(!filesystem.isSymlink(executable))
    }

    @Test func non_existent_file_is_not_symlink_or_directory() {
        let path = "/path/that/does/not/exist"

        #expect(!filesystem.isDirectory(path))
        #expect(!filesystem.isSymlink(path))
    }

    @Test func moving_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(filesystem.fileExists(executable))

        let newExecutable = executable.replacingOccurrences(of: "/exec.sh", with: "/file.txt")

        try! filesystem.move(from: executable, to: newExecutable)

        #expect(filesystem.fileExists(newExecutable))
        #expect(!filesystem.fileExists(executable))
    }

    @Test func deleting_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(filesystem.fileExists(executable))

        try! filesystem.remove(executable)

        #expect(!filesystem.fileExists(executable))
    }
}
