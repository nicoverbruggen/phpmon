//
//  RealFileSystemTest.swift
//  Unit Tests
//
//  Created by Nico Verbruggen on 02/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class RealFileSystemTest: XCTestCase {
    override func setUp() {
        ActiveFileSystem.useSystem()
    }

    private func createUniqueTemporaryDirectory() -> String {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        let fullTempDirectoryPath = tempDirectoryURL.appendingPathComponent("phpmon-fs-tests").path
        try? FileManager.default.removeItem(atPath: fullTempDirectoryPath)
        try! FileManager.default.createDirectory(atPath: fullTempDirectoryPath, withIntermediateDirectories: false)
        return fullTempDirectoryPath
    }

    func test_testable_fs_is_in_use() {
        XCTAssertTrue(FileSystem is RealFileSystem)
    }

    func test_temporary_path_exists() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        // True
        XCTAssertTrue(FileSystem.directoryExists(temporaryDirectory))
        XCTAssertTrue(FileSystem.anyExists(temporaryDirectory))

        // False
        XCTAssertFalse(FileSystem.fileExists(temporaryDirectory))
    }

    private func createTestBinaryFile(_ temporaryDirectory: String) -> String {
        let executablePath = "\(temporaryDirectory)/exec.sh"

        try! FileSystem.writeAtomicallyToFile(executablePath, content: """
            !#/bin/bash
            echo 'Hello world';
            """)

        return executablePath
    }

    func test_make_binary_executable() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        XCTAssertTrue(FileSystem.isWriteableFile(executable))
        XCTAssertFalse(FileSystem.isExecutableFile(executable))

        try! FileSystem.makeExecutable(executable)

        XCTAssertTrue(FileSystem.isExecutableFile(executable))
    }

    func test_moving_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        XCTAssertTrue(FileSystem.fileExists(executable))

        let newExecutable = executable.replacingOccurrences(of: "/exec.sh", with: "/file.txt")

        try! FileSystem.move(from: executable, to: newExecutable)

        XCTAssertTrue(FileSystem.fileExists(newExecutable))
        XCTAssertFalse(FileSystem.fileExists(executable))
    }

    func test_deleting_file() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        XCTAssertTrue(FileSystem.fileExists(executable))

        try! FileSystem.remove(executable)

        XCTAssertFalse(FileSystem.fileExists(executable))
    }

}
