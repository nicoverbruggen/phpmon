//
//  Filesystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Foundation

class Filesystem {

    /**
     Checks if a given path is a file *and* executable.
     */
    public static func isExecutableFile(_ path: String) -> Bool {
        return FileManager.default.isExecutableFile(
            atPath: path.replacingTildeWithHomeDirectory
        )
    }

    /**
     Checks if a file or directory exists at the provided path.
     */
    public static func exists(_ path: String) -> Bool {
        return FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory
        )
    }

    /**
     Checks if a file exists at the provided path.
     */
    public static func fileExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory,
            isDirectory: &isDirectory
        )

        return exists && !isDirectory.boolValue
    }

    /**
     Checks if a directory exists at the provided path.
     */
    public static func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory,
            isDirectory: &isDirectory
        )

        return exists && isDirectory.boolValue
    }

    /**
     Checks if a given file is a symbolic link.
     */
    public static func fileIsSymlink(_ path: String) -> Bool {
        do {
            let attribs = try FileManager.default.attributesOfItem(atPath: path)
            return attribs[.type] as! FileAttributeType == FileAttributeType.typeSymbolicLink
        } catch {
            return false
        }
    }

}

extension String {

    var replacingTildeWithHomeDirectory: String {
        return self.replacingOccurrences(of: "~", with: Paths.homePath)
    }

}
