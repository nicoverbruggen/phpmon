//
//  AppDelegate.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    // MARK: - Variables
    
    /**
     The Shell singleton that keeps track of the history of all
     (invoked by PHP Monitor) shell commands. It is used to
     invoke all commands in this application.
     */
    let sharedShell : Shell
    
    /**
     The App singleton contains information about the state of
     the application and global variables.
     */
    let state : App
    
    /**
     The MainMenu singleton is responsible for rendering the
     menu bar item and its menu, as well as its actions.
     */
    let menu : MainMenu
    
    /**
     The paths singleton that determines where Homebrew is installed,
     and where to look for binaries.
     */
    let paths : Paths
    
    // MARK: - Initializer
    
    /**
     When the application initializes, create all singletons.
     */
    override init() {
        self.sharedShell = Shell.user
        self.state = App.shared
        self.menu = MainMenu.shared
        self.paths = Paths.shared
        super.init()
    }
    
    // MARK: - Lifecycle
    
    /**
     When the application has finished launching, we'll want to set up
     the user notification center delegate, and kickoff the menu
     startup procedure.
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        self.menu.startup()
    }
    
    // MARK: - NSUserNotificationCenterDelegate
    
    /**
     When a notification is sent, the delegate of the notification center
     is asked whether the notification should be presented or not. Since
     the user can now disable notifications per application since macOS
     Catalina, any and all notifications should be displayed.
     */
    func userNotificationCenter(
        _ center: NSUserNotificationCenter,
        shouldPresent notification: NSUserNotification
    ) -> Bool {
        return true
    }
}
