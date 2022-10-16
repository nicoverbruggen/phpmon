//
//  TestableFileSystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableFileSystem: FileSystemProtocol {
    init(files: [String: FakeFile]) {
        self.files = files
    }

    var files: [String: FakeFile]

    func isExecutableFile(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return file.type == .binary
    }

    func exists(_ path: String) -> Bool {
        return files.keys.contains(path)
    }

    func fileExists(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return [.binary, .symlink, .text].contains(file.type)
    }

    func directoryExists(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return [.directory].contains(file.type)
    }

    func fileIsSymlink(_ path: String) -> Bool {
        guard let file = files[path] else {
            return false
        }

        return file.type == .symlink
    }
}

enum FakeFileType: Codable {
    case binary, text, directory, symlink
}

struct FakeFile: Codable {
    var type: FakeFileType
    var content: String?

    public static func fake(_ type: FakeFileType, _ content: String? = nil) -> FakeFile {
        return FakeFile(type: type, content: content)
    }
}
