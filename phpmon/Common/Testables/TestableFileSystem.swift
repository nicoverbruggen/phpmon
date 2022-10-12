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
        // TODO
        return false
    }

    func exists(_ path: String) -> Bool {
        // TODO
        return false
    }

    func fileExists(_ path: String) -> Bool {
        // TODO
        return false
    }

    func directoryExists(_ path: String) -> Bool {
        // TODO
        return false
    }

    func fileIsSymlink(_ path: String) -> Bool {
        // TODO
        return false
    }
}

enum FakeFileType {
    case binary, text, directory, symlink
}

struct FakeFile {
    var type: FakeFileType
    var content: String?

    public static func fake(_ type: FakeFileType, _ content: String? = nil) -> FakeFile {
        return FakeFile(type: type, content: content)
    }
}
