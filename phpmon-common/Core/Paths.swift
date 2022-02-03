//
//  Paths.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 The `Paths` class is used to locate various binaries on the system.
 The path to the Homebrew directory and the user's name are fetched only once, at boot.
 */
public class Paths {
    
    public static let shared = Paths()
    
    private var baseDir : Paths.HomebrewDir
    
    private var userName : String
    
    init() {
        baseDir = Shell.fileExists("\(HomebrewDir.opt.rawValue)/bin/brew") ? .opt : .usr
        userName = String(Shell.pipe("whoami").split(separator: "\n")[0])
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
    
    // MARK: - Enum
    
    public enum HomebrewDir: String {
        case opt = "/opt/homebrew"
        case usr = "/usr/local"
    }
    
}
