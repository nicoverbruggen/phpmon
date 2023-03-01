//
//  Paths.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 The `Paths` class is used to locate various binaries on the system.
 The path to the Homebrew directory and the user's name are fetched only once, at boot.
 */
public class Paths {

    public static let shared = Paths()

    internal var baseDir: Paths.HomebrewDir
    private var userName: String

    init() {
        baseDir = App.architecture != "x86_64" ? .opt : .usr
        userName = identity()
        Log.info("The current username is `\(userName)`.")
    }

    public func detectBinaryPaths() {
        detectComposerBinary()
    }

    // - MARK: Binaries

    public static var valet: String {
        return "\(binPath)/valet"
    }

    public static var brew: String {
        return "\(binPath)/brew"
    }

    public static var php: String {
        return "\(binPath)/php"
    }

    public static var phpConfig: String {
        return "\(binPath)/php-config"
    }

    // - MARK: Detected Binaries

    /** The path to the Composer binary. Can be in multiple locations, so is detected instead. */
    public static var composer: String?

    // - MARK: Paths

    public static var whoami: String {
        return shared.userName
    }

    public static var homePath: String {
        if FileSystem is RealFileSystem {
            return NSHomeDirectory()
        }

        if FileSystem is TestableFileSystem {
            let fs = FileSystem as! TestableFileSystem
            return fs.homeDirectory
        }

        fatalError("A valid FileSystem must be allowed to return the home path")
    }

    public static var cellarPath: String {
        return "\(shared.baseDir.rawValue)/Cellar"
    }

    public static var binPath: String {
        return "\(shared.baseDir.rawValue)/bin"
    }

    public static var optPath: String {
        return "\(shared.baseDir.rawValue)/opt"
    }

    public static var etcPath: String {
        return "\(shared.baseDir.rawValue)/etc"
    }

    public static var caskroomPath: String {
        return "\(shared.baseDir.rawValue)/Caskroom/"
            + (App.identifier.contains(".dev") ? "phpmon-dev" : "phpmon")
    }

    // MARK: - Flexible Binaries
    // (these can be in multiple locations, so we scan common places because)
    // (PHP Monitor will not use the user's own PATH)

    private func detectComposerBinary() {
        if FileSystem.fileExists("/usr/local/bin/composer") {
            Paths.composer = "/usr/local/bin/composer"
        } else if FileSystem.fileExists("/opt/homebrew/bin/composer") {
            Paths.composer = "/opt/homebrew/bin/composer"
        } else {
            Paths.composer = nil
            Log.warn("Composer was not found.")
        }
    }

    // MARK: - Enum

    public enum HomebrewDir: String {
        case opt = "/opt/homebrew"
        case usr = "/usr/local"
    }

}
