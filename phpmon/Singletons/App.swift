//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//
import Cocoa

class App {
    
    static let shared = App()
    
    static var phpInstall: PhpInstall? {
        return App.shared.currentInstall
    }
    
    static var busy: Bool {
        return App.shared.busy
    }
    
    /**
     Whether the application is busy switching versions.
     */
    var busy: Bool = false
    
    /**
     The currently active installation of PHP.
     */
    var currentInstall: PhpInstall? = nil
    
    /**
     All available versions of PHP.
     */
    var availablePhpVersions : [String] = []
    
    /**
     The timer that will periodically fetch the PHP version that is currently active.
     */
    var timer: Timer?
    
    /**
     Information we were able to discern from the Homebrew info command (as JSON).
     */
    var brewPhpPackage: HomebrewPackage? = nil {
        didSet {
            self.brewPhpVersion = self.brewPhpPackage!.getVersion()
        }
    }
    
    /**
     The version that the `php` formula via Brew is aliased to on the current system.
     
     If you're up to date, `php` will be aliased to the latest version,
     but that might not be the case.
     
     We'll technically default to version 8.0, but the information should always be loaded
     from Homebrew itself upon starting the application.
     */
    var brewPhpVersion: String = "8.0"
    
}
