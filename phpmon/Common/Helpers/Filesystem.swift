//
//  FileSystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Filesystem {

    /**
     Checks if a file exists at the provided path.
     Uses `FileManager`.
     */
    public static func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(
            atPath: path.replacingOccurrences(of: "~", with: "/Users/\(Paths.whoami)")
        )
    }

}
