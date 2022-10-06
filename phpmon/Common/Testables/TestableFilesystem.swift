//
//  TestableFilesystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableFilesystem {}

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
