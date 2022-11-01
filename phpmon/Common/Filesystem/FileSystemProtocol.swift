//
//  FileSystemProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol FileSystemProtocol {

    // MARK: - Basics

    func createDirectory(_ path: String, withIntermediateDirectories: Bool) throws

    func writeAtomicallyToFile(_ path: String, content: String) throws

    func readStringFromFile(_ path: String) throws -> String

    // MARK: - Move & Delete Files

    func move(from path: String, to newPath: String) throws

    func remove(_ path: String) throws

    // MARK: — Attributes

    func makeExecutable(_ path: String) throws

    // MARK: - Checks

    func isExecutableFile(_ path: String) -> Bool

    func isWriteableFile(_ path: String) -> Bool

    func anyExists(_ path: String) -> Bool

    func fileExists(_ path: String) -> Bool

    func directoryExists(_ path: String) -> Bool

    func fileIsSymlink(_ path: String) -> Bool
}
