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
    
    /**
     The PhpSwitcher singleton that handles PHP version
     detection, as well as switching. It is initialized
     when the app is ready and passed all checks.
     */
    var switcher: PhpEnv! = nil
    
    var logger = Log.shared
    
    // MARK: - Initializer
    
    /**
     When the application initializes, create all singletons.
     */
    override init() {
        logger.verbosity = .performance
        Log.info("==================================")
        Log.info("PHP MONITOR by Nico Verbruggen")
        Log.info("Version \(App.version)")
        Log.info("==================================")
        self.sharedShell = Shell.user
        self.state = App.shared
        self.menu = MainMenu.shared
        self.paths = Paths.shared
        self.valet = Valet.shared
        super.init()
    }
    
    func initializeSwitcher() {
        self.switcher = PhpEnv.shared
        self.switcher.delegate = self.state
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
