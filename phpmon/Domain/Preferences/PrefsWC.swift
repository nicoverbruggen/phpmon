//
//  PrefsWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

struct Keys {
    static let Escape = 53
    static let Space = 49
}

class PrefsWC: PMWindowController {
    
    // MARK: - Window Identifier
    
    override var windowName: String {
        return "Preferences"
    }
    
    // MARK: - Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    // MARK: - Key Interaction
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        if let vc = self.contentViewController as? PrefsVC {
            if vc.listeningForGlobalHotkey {
                if event.keyCode == Keys.Escape || event.keyCode == Keys.Space {
                    print("A blacklisted key was pressed, canceling listen")
                    vc.listeningForGlobalHotkey = false
                } else {
                    vc.updateGlobalShortcut(event)
                }
            }
        }
    }
    
}
