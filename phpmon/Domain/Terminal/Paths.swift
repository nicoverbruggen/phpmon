//
//  Paths.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum HomebrewDir: String {
    case opt = "/opt/homebrew"
    case usr = "/usr/local"
}

class Paths {

    static let shared = Paths()
    var baseDir: HomebrewDir
    var userName: String

    init() {
        let shell = App.shared.container.shell
        self.userName = String(shell.sync("whoami").out.split(separator: "\n")[0])

        let optBrewFound = App.shared.container.filesystem.fileExists("\(HomebrewDir.opt.rawValue)/bin/brew")
        let usrBrewFound = App.shared.container.filesystem.fileExists("\(HomebrewDir.usr.rawValue)/bin/brew")

        if optBrewFound {
            // This is usually the case with Homebrew installed on Apple Silicon
            baseDir = .opt
        } else if usrBrewFound {
            // This is usually the case with Homebrew installed on Intel (or Rosetta 2)
            baseDir = .usr
        } else {
            // Falling back to default "legacy" Homebrew location (for Intel)
            print("Seems like we couldn't determine the Homebrew directory.")
            print("This usually means we're in trouble... (no Homebrew?)")
            baseDir = .usr
        }
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

    // - MARK: Paths

    public static var whoami: String {
        return shared.userName
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

}
