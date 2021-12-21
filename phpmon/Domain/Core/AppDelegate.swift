//
//  AppDelegate.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Variables
    
    /**
     The Shell singleton that keeps track of the history of all
     (invoked by PHP Monitor) shell commands. It is used to
     invoke all commands in this application.
     */
    let sharedShell: Shell
    
    /**
     The PhpSwitcher singleton that handles PHP version
     detection, as well as switching.
     
     - Note: It is important to initialize the switcher
     before the `App` singleton, so that the delegate
     is set correctly.
     */
    let switcher: PhpSwitcher
    
    /**
     The App singleton contains information about the state of
     the application and global variables.
     */
    let state: App
    
    /**
     The MainMenu singleton is responsible for rendering the
     menu bar item and its menu, as well as its actions.
     */
    let menu: MainMenu
    
    /**
     The paths singleton that determines where Homebrew is installed,
     and where to look for binaries.
     */
    let paths: Paths
    
    /**
     The Valet singleton that determines all information
     about Valet and its current configuration.
     */
    let valet: Valet
    
    // MARK: - Initializer
    
    /**
     When the application initializes, create all singletons.
     */
    override init() {
        print("==================================")
        print("PHP MONITOR by Nico Verbruggen")
        print("Version \(App.version)")
        print("==================================")
        self.sharedShell = Shell.user
        self.switcher = PhpSwitcher.shared
        self.state = App.shared
        self.menu = MainMenu.shared
        self.paths = Paths.shared
        self.valet = Valet.shared
        super.init()
    }
    
    // MARK: - Lifecycle
    
    /**
     When the application has finished launching, we'll want to set up
     the user notification center permissions, and kickoff the menu
     startup procedure.
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Make sure notifications will work
        setupNotifications()
        // Make sure the menu performs its initial checks
        menu.startup()
    }
    
}
