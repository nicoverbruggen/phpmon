//
//  PrefsWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class PrefsWC: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if let vc = self.contentViewController as? PrefsVC {
            if vc.listening {
                vc.updateGlobalShortcut(event)
            }
        }
    }
    
}
