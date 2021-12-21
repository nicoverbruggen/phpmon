//
//  Paths.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 The `Paths` class is used to locate various binaries on the system,
 and provides a full
 */
public class Paths {
    
    public static let shared = Paths()
    
    private var baseDir : Paths.HomebrewDir
    
    init() {
        baseDir = Shell.fileExists("\(HomebrewDir.opt.rawValue)/bin/brew") ? .opt : .usr
    }
    
    // - MARK: Binaries
    
    public static var valet: String {
        return "/Users/\(whoami)/.composer/vendor/bin/valet"
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
        return String(Shell.pipe("whoami").split(separator: "\n")[0])
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
