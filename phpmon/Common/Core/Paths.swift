//
//  Paths.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import os

// `nonisolated` + `Sendable`: `Paths` is a leaf that is read from off-main
// contexts (shell/command building, actors) while composing binary paths, so it
// must not be main-actor isolated. All stored properties are immutable (`let`)
// or thread-safe (`OSAllocatedUnfairLock`), which makes the type genuinely `Sendable`.
/**
 The `Paths` class is used to locate various binaries on the system.
 The path to the Homebrew directory and the user's name are fetched only once, at boot.
 */
public nonisolated final class Paths: Sendable {
    internal let container: Container
    internal let baseDir: Paths.HomebrewDir
    private let userName: String

    init(container: Container) {
        // Assume the default directory is correct
        var resolvedBaseDir: Paths.HomebrewDir =
            container.systemContext.architecture != "x86_64" ? .opt : .usr

        // Ensure that if a different location is used, it takes precendence
        if resolvedBaseDir == .usr
            && container.filesystem.directoryExists("/usr/local/homebrew")
            && !container.filesystem.directoryExists("/usr/local/Cellar") {
            Log.warn("Using /usr/local/homebrew as base directory!")
            resolvedBaseDir = .usr_hb
        }

        self.baseDir = resolvedBaseDir
        self.userName = identity()

        if !isRunningSwiftUIPreview {
            Log.info("The current username is `\(userName)`.")
            if container.systemContext.shell.configured == container.systemContext.shell.resolved {
                Log.info("The user's shell is `\(container.systemContext.shell.configured)`. Using `\(container.systemContext.shell.resolved)`.")
            } else {
                Log.info("Using `\(container.systemContext.shell.resolved)` as the shell, since `\(container.systemContext.shell.configured)` isn't accessible.")
            }
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

    public var composer: String? {
        get { _composer.withLock { $0 } }
        set { _composer.withLock { $0 = newValue } }
    }

    private let _composer = OSAllocatedUnfairLock<String?>(initialState: nil)

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
        return container.systemContext.shell.resolved
    }

    /**
     Returns the shell path configured for the user account (which may be invalid).
     */
    public var configuredShellPath: String {
        return container.systemContext.shell.configured
    }

    /**
     Indicates whether the configured shell is valid and executable.
     */
    public var isConfiguredShellValid: Bool {
        return container.systemContext.shell.isValid
    }

    // MARK: - Enum

    public nonisolated enum HomebrewDir: String, Sendable {
        case opt = "/opt/homebrew"
        case usr = "/usr/local"
        case usr_hb = "/usr/local/homebrew"
    }

}
