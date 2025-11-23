//
//  TestableFileSystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableFileSystem: FileSystemProtocol {

    /**
     Initialize a fake filesystem with a bunch of files.
     You do not need to specify directories (unless symlinks), those will be created automatically.
     */
    init(files: [String: FakeFile]) {
        self.files = files

        // Ensure that each of the ~ characters are replaced with the home directory path
        accessQueue.sync {
            for (key, value) in files {
                let adjustedKey = key.contains("~") ? key.replacing("~", with: self.homeDirectory) : key
                self.files[adjustedKey] = value
            }

            // Ensure that intermediate directories are created
            for file in self.files {
                self.createIntermediateDirectories(file.key)
            }
        }
    }

    /**
     Internal file handling of the fake filesystem.
     You can easily dump what's in here by using:
     ```
     let fs = FileSystem as! TestableFileSystem
     fs.printContents()
     ```
     */
    private(set) var files: [String: FakeFile]

    /**
     The home directory for the fake filesystem.
     */
    private(set) var homeDirectory = "/Users/fake"

    /**
     Serial dispatch queue for ensuring thread-safe access to the `files` dictionary.
     */
    private let accessQueue = DispatchQueue(label: "com.testablefilesystem.accessQueue")

    // MARK: - Basics

    func createDirectory(_ path: String, withIntermediateDirectories: Bool) throws {
        let path = path.replacingTildeWithHomeDirectory

        try accessQueue.sync {
            if files[path] != nil {
                throw TestableFileSystemError.alreadyExists
            }

            self.createIntermediateDirectories(path)

            self.files[path] = .fake(.directory)
        }
    }

    func writeAtomicallyToFile(_ path: String, content: String) throws {
        let path = path.replacingTildeWithHomeDirectory

        try accessQueue.sync {
            if files[path] != nil {
                throw TestableFileSystemError.alreadyExists
            }

            self.files[path] = .fake(.text, content)
        }
    }

    func getStringFromFile(_ path: String) throws -> String {
        let path = path.replacingTildeWithHomeDirectory

        return try accessQueue.sync {
            guard let file = files[path] else {
                throw TestableFileSystemError.fileMissing
            }

            return file.content ?? ""
        }
    }

    func getShallowContentsOfDirectory(_ path: String) throws -> [String] {
        let path = path.replacingTildeWithHomeDirectory

        var seek = path
        if !seek.hasSuffix("/") {
            seek = "\(seek)/"
        }

        return accessQueue.sync {
            self.files.keys
                .filter { $0.hasPrefix(seek) }
                .map { $0.replacing(seek, with: "") }
                .filter { !$0.contains("/") }
        }
    }

    func getDestinationOfSymlink(_ path: String) throws -> String {
        let path = path.replacingTildeWithHomeDirectory

        return try accessQueue.sync {
            guard let file = files[path] else {
                throw TestableFileSystemError.fileMissing
            }

            if file.type != .symlink {
                throw TestableFileSystemError.notSymlink
            }

            guard let pathToSymlink = file.content else {
                throw TestableFileSystemError.invalidSymlink
            }

            if !files.keys.contains(pathToSymlink) {
                throw TestableFileSystemError.invalidSymlink
            }

            return pathToSymlink
        }
    }

    // MARK: - Move & Delete Files

    func move(from path: String, to newPath: String) throws {
        let path = path.replacingTildeWithHomeDirectory
        let newPath = newPath.replacingTildeWithHomeDirectory

        accessQueue.sync {
            self.files.keys.forEach { key in
                if key.hasPrefix(path) {
                    self.files.renameKey(
                        fromKey: key,
                        toKey: key.replacing(path, with: newPath)
                    )
                }
            }

            self.files.renameKey(fromKey: path, toKey: newPath)
        }
    }

    func remove(_ path: String) throws {
        accessQueue.sync {
            // Remove recursively
            self.files.keys.forEach { key in
                if key.hasPrefix(path) {
                    self.files.removeValue(forKey: key)
                }
            }

            self.files.removeValue(forKey: path)
        }
    }

    // MARK: — Attributes

    func makeExecutable(_ path: String) throws {
        let path = path.replacingTildeWithHomeDirectory

        try accessQueue.sync {
            guard let file = files[path] else {
                throw TestableFileSystemError.fileMissing
            }

            file.type = .binary
        }
    }

    // MARK: - Checks

    func isExecutableFile(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path.replacingTildeWithHomeDirectory] else {
                return false
            }

            return file.type == .binary
        }
    }

    func isWriteableFile(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path.replacingTildeWithHomeDirectory] else {
                return false
            }

            return !file.readOnly
        }
    }

    func anyExists(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            files.keys.contains(path)
        }
    }

    func fileExists(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path] else {
                return false
            }

            return [.binary, .symlink, .text].contains(file.type)
        }
    }

    func directoryExists(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path] else {
                return false
            }

            return [.directory].contains(file.type)
        }
    }

    func isSymlink(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path] else {
                return false
            }

            return file.type == .symlink
        }
    }

    func isDirectory(_ path: String) -> Bool {
        let path = path.replacingTildeWithHomeDirectory

        return accessQueue.sync {
            guard let file = files[path] else {
                return false
            }

            return file.type == .directory
        }
    }

    public func printContents() {
        accessQueue.sync {
            for key in self.files.keys.sorted() {
                print("\(key) -> \(self.files[key]!.type)")
            }
        }
    }

    private func createIntermediateDirectories(_ path: String) {
        let path = path.replacingTildeWithHomeDirectory
        let items = path.components(separatedBy: "/")
        var preceding = ""

        var directoriesToCreate: [String] = []

        for item in items {
            let key = preceding == "/" ? "/\(item)" : "\(preceding)/\(item)"
            directoriesToCreate.append(key)
            preceding = key
        }

        for key in directoriesToCreate where !self.files.keys.contains(key) {
            self.files[key] = .fake(.directory)
        }
    }
}

enum FakeFileType: Codable {
    case binary, text, directory, symlink
}

class FakeFile: Codable {
    var type: FakeFileType
    var content: String?
    var readOnly: Bool = false

    init(type: FakeFileType, content: String?, readOnly: Bool = false) {
        self.type = type
        self.content = content
        self.readOnly = readOnly
    }

    public static func fake(
        _ type: FakeFileType,
        _ content: String? = nil,
        readOnly: Bool = false
    ) -> FakeFile {
        return FakeFile(
            type: type,
            content: content,
            readOnly: readOnly
        )
    }
}

enum TestableFileSystemError: Error {
    case fileMissing
    case alreadyExists
    case notSymlink
    case invalidSymlink
}
