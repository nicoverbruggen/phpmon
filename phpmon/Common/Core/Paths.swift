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
    internal let container: Container
    internal var baseDir: Paths.HomebrewDir
    private var userName: String
    private var preferredShell: String

    init(container: Container = App.shared.container) {
        // Assume the default directory is correct
        baseDir = App.architecture != "x86_64" ? .opt : .usr

        // Ensure that if a different location is used, it takes precendence
        if baseDir == .usr
            && container.filesystem.directoryExists("/usr/local/homebrew")
            && !container.filesystem.directoryExists("/usr/local/Cellar") {
            Log.warn("Using /usr/local/homebrew as base directory!")
            baseDir = .usr_hb
        }

        userName = identity()
        preferredShell = preferred_shell()

        if !isRunningSwiftUIPreview {
            Log.info("The current username is `\(userName)`.")
            Log.info("The user's shell is `\(preferredShell)`.")
        }

        self.container = container
    }

    public func detectBinaryPaths() {
        detectComposerBinary()
    }

    // - MARK: Binaries

    public var valet: String {
        return "\(binPath)/valet"
    }

    public var brew: String {
        return "\(binPath)/brew"
    }

    public var php: String {
        return "\(binPath)/php"
    }

    public var phpConfig: String {
        return "\(binPath)/php-config"
    }

    // - MARK: Detected Binaries

    /** The path to the Composer binary. Can be in multiple locations, so is detected instead. */
    public var composer: String?

    // - MARK: Paths

    public var whoami: String {
        return userName
    }

    public var homePath: String {
        if container.filesystem is RealFileSystem {
            return NSHomeDirectory()
        }

        if container.filesystem is TestableFileSystem {
            let fs = container.filesystem as! TestableFileSystem
            return fs.homeDirectory
        }

        fatalError("A valid FileSystem must be allowed to return the home path")
    }

    public var cellarPath: String {
        return "\(baseDir.rawValue)/Cellar"
    }

    public var binPath: String {
        return "\(baseDir.rawValue)/bin"
    }

    public var optPath: String {
        return "\(baseDir.rawValue)/opt"
    }

    public var etcPath: String {
        return "\(baseDir.rawValue)/etc"
    }

    public var tapPath: String {
        if baseDir == .usr {
            return "\(baseDir.rawValue)/homebrew/Library/Taps"
        }

        return "\(baseDir.rawValue)/Library/Taps"
    }

    public var caskroomPath: String {
        return "\(baseDir.rawValue)/Caskroom/phpmon"
    }

    public var shell: String {
        return preferredShell
    }

    // MARK: - Flexible Binaries
    // (these can be in multiple locations, so we scan common places because)
    // (PHP Monitor will not use the user's own PATH)

    private func detectComposerBinary() {
        if container.filesystem.fileExists("/usr/local/bin/composer") {
            composer = "/usr/local/bin/composer"
        } else if container.filesystem.fileExists("/opt/homebrew/bin/composer") {
            composer = "/opt/homebrew/bin/composer"
        } else if container.filesystem.fileExists("/usr/local/homebrew/bin/composer") {
            composer = "/usr/local/homebrew/bin/composer"
        } else {
            composer = nil
            Log.warn("Composer was not found.")
        }
    }

    // MARK: - Enum

    public enum HomebrewDir: String {
        case opt = "/opt/homebrew"
        case usr = "/usr/local"
        case usr_hb = "/usr/local/homebrew"
    }

}
