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

    func test_directory_can_be_created_symlinked_and_read() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()

        let folderPath = "\(temporaryDirectory)/brew/etc/lib/c"

        try! FileSystem.createDirectory(folderPath, withIntermediateDirectories: true)

        XCTAssertTrue(FileSystem.directoryExists("\(temporaryDirectory)/brew"))
        XCTAssertTrue(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc"))
        XCTAssertTrue(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc/lib"))
        XCTAssertTrue(FileSystem.directoryExists("\(temporaryDirectory)/brew/etc/lib/c"))

        _ = system("ln -s \(temporaryDirectory)/brew/etc/lib/c \(temporaryDirectory)/c")
        XCTAssertTrue(FileSystem.directoryExists("\(temporaryDirectory)/c"))
        XCTAssertTrue(FileSystem.isSymlink("\(temporaryDirectory)/c"))
        XCTAssertEqual(
            try! FileSystem.getDestinationOfSymlink("\(temporaryDirectory)/c"),
            "\(temporaryDirectory)/brew/etc/lib/c"
        )

        let contents = try! FileSystem.getShallowContentsOfDirectory("\(temporaryDirectory)/brew/etc/lib/c")
        XCTAssertEqual([], contents)
    }

    private func createTestBinaryFile(_ temporaryDirectory: String) -> String {
        let executablePath = "\(temporaryDirectory)/exec.sh"

        try! FileSystem.writeAtomicallyToFile(executablePath, content: """
            !#/bin/bash
            echo 'Hello world';
            """)

        return executablePath
    }



    func test_can_read_file_as_text() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        XCTAssertEqual(
            try! FileSystem.getStringFromFile(executable),
            """
            !#/bin/bash
            echo 'Hello world';
            """
        )
    }

    func test_make_binary_executable() {
        let temporaryDirectory = self.createUniqueTemporaryDirectory()
        let executable = self.createTestBinaryFile(temporaryDirectory)

        XCTAssertTrue(FileSystem.isWriteableFile(executable))
        XCTAssertFalse(FileSystem.isExecutableFile(executable))

        try! FileSystem.makeExecutable(executable)

        XCTAssertTrue(FileSystem.isExecutableFile(executable))
        XCTAssertFalse(FileSystem.isDirectory(executable))
        XCTAssertFalse(FileSystem.isSymlink(executable))
    }

    func test_non_existent_file_is_not_symlink_or_directory() {
        let path = "/path/that/does/not/exist"

        XCTAssertFalse(FileSystem.isDirectory(path))
        XCTAssertFalse(FileSystem.isSymlink(path))
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
