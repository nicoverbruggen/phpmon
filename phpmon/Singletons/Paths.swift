//
//  Paths.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/01/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum HomebrewDirectory: String {
    case opt = "/opt/homebrew/bin"
    case usr = "/usr/local/bin"
}

class Paths {
    
    static let shared = Paths()
    var baseDirectory : HomebrewDirectory
    
    init() {
        let optBrewFound = Shell.fileExists("\(HomebrewDirectory.opt.rawValue)/brew")
        let usrBrewFound = Shell.fileExists("\(HomebrewDirectory.usr.rawValue)/brew")
        
        if (optBrewFound) {
            self.baseDirectory = .opt
        } else if (usrBrewFound) {
            self.baseDirectory = .usr
        } else {
            // Falling back to Intel
            print("Seems like we couldn't determine the architecture.")
            print("This usually means we're in trouble... (no Homebrew?)")
            self.baseDirectory = .usr
        }
        
        print("Homebrew directory: \(self.baseDirectory)")
    }
    
    public static func brew() -> String {
        return "\(self.binPath())/brew"
    }
    
    public static func php() -> String {
        return "\(self.binPath())/php"
    }
    
    public static func binPath() -> String {
        return self.shared.baseDirectory.rawValue
    }
    
    public static func optPath() -> String {
        switch self.shared.baseDirectory {
        case .opt:
            return "/opt/homebrew/opt"
        case .usr:
            return "/usr/local/opt"
        }
    }
    
    public static func etcPath() -> String {
        switch self.shared.baseDirectory {
        case .opt:
            return "/opt/homebrew/etc"
        case .usr:
            return "/usr/local/etc"
        }
    }
}


