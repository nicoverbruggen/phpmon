//
//  PhpSwitcher.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol PhpSwitcherDelegate: AnyObject {
    func switcherDidStartSwitching()
    func switcherDidCompleteSwitch()
}

class PhpSwitcher {
    
    init() {
        self.currentInstall = ActivePhpInstallation()
    }
    
    /** The delegate that is informed of updates. */
    weak var delegate: PhpSwitcherDelegate?

    /** The static app instance. Accessible at any time. */
    static let shared = PhpSwitcher()
    
    /** Whether the switcher is busy performing any actions. */
    var isBusy: Bool = false
    
    /** All available versions of PHP. */
    var availablePhpVersions: [String] = []
    
    /** Cached information about the PHP installations. */
    var cachedPhpInstallations: [String: PhpInstallation] = [:]
    
    /** Static accessor for `PhpSwitcher.shared.currentInstall`. */
    static var phpInstall: ActivePhpInstallation {
        return Self.shared.currentInstall
    }
    
    /** Information about the currently linked PHP installation. */
    var currentInstall: ActivePhpInstallation
    
    /**
     The version that the `php` formula via Brew is aliased to on the current system.
     
     If you're up to date, `php` will be aliased to the latest version,
     but that might not be the case.
     */
    var brewPhpVersion: String {
        return homebrewPackage.version
    }
    
    /**
     Information we were able to discern from the Homebrew info command.
     */
    var homebrewPackage: HomebrewPackage! = nil
    
}
