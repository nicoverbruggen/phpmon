//
//  FileSystemProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol FileSystemProtocol {
    /**
     Checks if a given path is a file *and* executable.
     */
    func isExecutableFile(_ path: String) -> Bool

    /**
     Checks if a file or directory exists at the provided path.
     */
    func exists(_ path: String) -> Bool

    /**
     Checks if a file exists at the provided path.
     */
    func fileExists(_ path: String) -> Bool

    /**
     Checks if a directory exists at the provided path.
     */
    func directoryExists(_ path: String) -> Bool

    /**
     Checks if a given file is a symbolic link.
     */
    func fileIsSymlink(_ path: String) -> Bool
}
