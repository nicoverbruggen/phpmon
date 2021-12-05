//
//  PMWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

/**
 This window class keeps track of which windows are currently visible, and reports this info back to the App class.
 For more information, check the `windows` property on `App`.
 
 - Note: This class does make a simple assumption: each window controller corresponds to a single view.
 */
class PMWindowController: NSWindowController, NSWindowDelegate {
    
    public var windowName: String {
        fatalError("Please specify a window name")
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        App.shared.register(window: windowName)
    }
    
    func windowWillClose(_ notification: Notification) {
        App.shared.remove(window: windowName)
    }
    
    deinit {
        print("Window controller '\(windowName)' was deinitialized")
    }
    
}
