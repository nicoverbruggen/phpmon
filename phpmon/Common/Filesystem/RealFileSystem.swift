//
//  RealFileSystem.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

extension String {
    var replacingTildeWithHomeDirectory: String {
        return self.replacingOccurrences(of: "~", with: Paths.homePath)
    }
}

class RealFileSystem: FileSystemProtocol {
    var container: Container

    init(container: Container) {
        self.container = container
    }

    // MARK: - Basics

    func createDirectory(_ path: String, withIntermediateDirectories: Bool) {
        try! FileManager.default.createDirectory(
            atPath: path.replacingTildeWithHomeDirectory,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }

    func writeAtomicallyToFile(_ path: String, content: String) throws {
        try content.write(
            to: URL(fileURLWithPath: path.replacingTildeWithHomeDirectory),
            atomically: true,
            encoding: String.Encoding.utf8
        )
    }

    func getStringFromFile(_ path: String) throws -> String {
        return try String(
            contentsOf: URL(fileURLWithPath: path.replacingTildeWithHomeDirectory),
            encoding: .utf8
        )
    }

    func getShallowContentsOfDirectory(_ path: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path.replacingTildeWithHomeDirectory)
    }

    func getDestinationOfSymlink(_ path: String) throws -> String {
        return try FileManager.default.destinationOfSymbolicLink(atPath: path.replacingTildeWithHomeDirectory)
    }

    // MARK: - Move & Delete Files

    func move(from path: String, to newPath: String) throws {
        try FileManager.default.moveItem(
            atPath: path.replacingTildeWithHomeDirectory,
            toPath: newPath.replacingTildeWithHomeDirectory
        )
    }

    func remove(_ path: String) throws {
        try FileManager.default.removeItem(atPath: path.replacingTildeWithHomeDirectory)
    }

    // MARK: — FS Attributes

    func makeExecutable(_ path: String) throws {
        _ = container.shell.sync("chmod +x \(path.replacingTildeWithHomeDirectory)")
    }

    // MARK: - Checks

    func isExecutableFile(_ path: String) -> Bool {
        return FileManager.default.isExecutableFile(
            atPath: path.replacingTildeWithHomeDirectory
        ) && FileManager.default.isReadableFile(
            atPath: path.replacingTildeWithHomeDirectory
        )
    }

    func isWriteableFile(_ path: String) -> Bool {
        return FileManager.default.isWritableFile(
            atPath: path.replacingTildeWithHomeDirectory
        )
    }

    func anyExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory
        )
    }

    func fileExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory,
            isDirectory: &isDirectory
        )

        return exists && !isDirectory.boolValue
    }

    func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(
            atPath: path.replacingTildeWithHomeDirectory,
            isDirectory: &isDirectory
        )

        return exists && isDirectory.boolValue
    }

    func isSymlink(_ path: String) -> Bool {
        do {
            let attribs = try FileManager.default.attributesOfItem(atPath: path)
            return attribs[.type] as! FileAttributeType == FileAttributeType.typeSymbolicLink
        } catch {
            return false
        }
    }

    func isDirectory(_ path: String) -> Bool {
        do {
            let attribs = try FileManager.default.attributesOfItem(atPath: path)
            return attribs[.type] as! FileAttributeType == FileAttributeType.typeDirectory
        } catch {
            return false
        }
    }
}
