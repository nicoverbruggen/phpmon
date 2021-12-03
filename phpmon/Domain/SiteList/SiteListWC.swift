//
//  SiteListWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class SiteListWC: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    /**
     Allow users to close the window using Cmd-W, a shortcut I definitely use a lot.
     */
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers! {
            case "w":
                self.window?.close()
            default:
                break
            }
        }
    }
    
}
