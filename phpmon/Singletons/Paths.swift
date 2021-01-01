//
//  Paths.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/01/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum HomebrewDir: String {
    case opt = "/opt/homebrew/bin"
    case usr = "/usr/local/bin"
}

class Paths {
    
    static let shared = Paths()
    var baseDir : HomebrewDir
    
    init() {
        let optBrewFound = Shell.fileExists("\(HomebrewDir.opt.rawValue)/brew")
        let usrBrewFound = Shell.fileExists("\(HomebrewDir.usr.rawValue)/brew")
        
        if (optBrewFound) {
            // This is usually the case with Homebrew installed on Apple Silicon
            self.baseDir = .opt
        } else if (usrBrewFound) {
            // This is usually the case with Homebrew installed on Intel (or Rosetta 2)
            self.baseDir = .usr
        } else {
            // Falling back to default "legacy" Homebrew location (for Intel)
            print("Seems like we couldn't determine the Homebrew directory.")
            print("This usually means we're in trouble... (no Homebrew?)")
            self.baseDir = .usr
        }
        
        print("Homebrew directory: \(self.baseDir)")
    }
    
    public static func brew() -> String {
        return "\(self.binPath())/brew"
    }
    
    public static func php() -> String {
        return "\(self.binPath())/php"
    }
    
    public static func binPath() -> String {
        return self.shared.baseDir.rawValue
    }
    
    public static func optPath() -> String {
        switch self.shared.baseDir {
        case .opt:
            return "/opt/homebrew/opt"
        case .usr:
            return "/usr/local/opt"
        }
    }
    
    public static func etcPath() -> String {
        switch self.shared.baseDir {
        case .opt:
            return "/opt/homebrew/etc"
        case .usr:
            return "/usr/local/etc"
        }
    }
}


