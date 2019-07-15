//
//  AppDelegate.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Variables
    let sharedShell : Shell
    let state : App
    let menu : MainMenu
    
    // MARK: - Initializer
    
    override init() {
        self.sharedShell = Shell.user
        self.state = App.shared
        self.menu = MainMenu.shared
        super.init()
    }
    
    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.menu.startup()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

