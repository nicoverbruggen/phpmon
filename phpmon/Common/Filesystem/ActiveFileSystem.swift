//
//  FS.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

var FileSystem: FileSystemProtocol {
    return ActiveFileSystem.shared
}

class ActiveFileSystem {
    static var shared: FileSystemProtocol = RealFileSystem()

    /** Note: Intermediate directories are not automatically inferred and have to be manually declared. */
    public static func useTestable(_ files: [String: FakeFile]) {
        Self.shared = TestableFileSystem(files: files)
    }

    public static func useSystem() {
        Self.shared = RealFileSystem()
    }
}
