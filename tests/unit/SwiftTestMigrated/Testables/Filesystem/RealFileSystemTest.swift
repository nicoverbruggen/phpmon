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
    init() throws {
        ActiveFileSystem.useSystem()
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

        try! FileSystem.writeAtomicallyToFile(executablePath, content: """
            !#/bin/bash
            echo 'Hello world';
            """)

        return executablePath
    }

    @Test func testable_fs_is_in_use() {
        #expect(FileSystem is RealFileSystem)
    }

    @Test func temporary_path_exists() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        // True
        #expect(FileSystem.directoryExists(temporaryDirectory))
        #expect(FileSystem.anyExists(temporaryDirectory))

        // False
        #expect(!FileSystem.fileExists(temporaryDirectory))
    }

    @Test func directory_can_be_created_symlinked_and_read() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        let folderPath = "\(temporaryDirectory)/brew/etc/lib/c"

        try! FileSystem.createDirectory(folderPath, withIntermediateDirectories: true)

        #expect(FileSystem.directoryExists("\(temporaryDirectory)/brew"))
        #expect(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc"))
        #expect(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc/lib"))
        #expect(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc/lib/c"))

        _ = system("ln -s \(temporaryDirectory)/brew/etc/lib/c \(temporaryDirectory)/c")
        #expect(FileSystem.directoryExists("\(temporaryDirectory)/c"))
        #expect(FileSystem.isSymlink("\(temporaryDirectory)/c"))
        #expect(
            try! FileSystem.getDestinationOfSymlink("\(temporaryDirectory)/c") ==
            "\(temporaryDirectory)/brew/etc/lib/c"
        )

        let contents = try! FileSystem.getShallowContentsOfDirectory("\(temporaryDirectory)/brew/etc/lib/c")
        #expect([] == contents)
    }

    @Test func can_read_file_as_text() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(
            try! FileSystem.getStringFromFile(executable) ==
            """
            !#/bin/bash
            echo 'Hello world';
            """
        )
    }

    @Test func make_binary_executable() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(FileSystem.isWriteableFile(executable))
        #expect(!FileSystem.isExecutableFile(executable))

        try! FileSystem.makeExecutable(executable)

        #expect(FileSystem.isExecutableFile(executable))
        #expect(!FileSystem.isDirectory(executable))
        #expect(!FileSystem.isSymlink(executable))
    }

    @Test func non_existent_file_is_not_symlink_or_directory() {
        let path = "/path/that/does/not/exist"

        #expect(!FileSystem.isDirectory(path))
        #expect(!FileSystem.isSymlink(path))
    }

    @Test func moving_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(FileSystem.fileExists(executable))

        let newExecutable = executable.replacingOccurrences(of: "/exec.sh", with: "/file.txt")

        try! FileSystem.move(from: executable, to: newExecutable)

        #expect(FileSystem.fileExists(newExecutable))
        #expect(!FileSystem.fileExists(executable))
    }

    @Test func deleting_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        #expect(FileSystem.fileExists(executable))

        try! FileSystem.remove(executable)

        #expect(!FileSystem.fileExists(executable))
    }
}
