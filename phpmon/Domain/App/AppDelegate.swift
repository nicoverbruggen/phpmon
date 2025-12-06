//
//  AppDelegate.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    static var instance: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }

    // MARK: - Variables

    /**
     The App singleton contains information about the state of
     the application and global variables.
     */
    let state: App

    /**
     The Valet singleton that determines all information
     about Valet and its current configuration.
     */
    let valet: Valet

    /**
     The Brew singleton that contains all information about Homebrew
     and its configuration on your system.
     */
    let brew: Brew

    /**
     The logger is responsible for different levels of logging.
     You can tweak the verbosity in the `init` method here.
     */
    var logger = Log.shared

    // MARK: - Initializer

    /**
     When the application initializes, create all singletons.
     */
    override init() {
        // Prepare the container with the defaults
        self.state = App.shared
        self.state.container.bind()

        #if DEBUG
        logger.verbosity = .performance
        Log.info("Extra verbose mode is enabled by default on DEBUG builds.")

        if let profile = CommandLine.arguments.first(where: { $0.matches(pattern: "--configuration:*") }) {
            AppDelegate.initializeTestingProfile(profile.replacing("--configuration:", with: ""))
        }
        #endif

        if CommandLine.arguments.contains("--v") {
            logger.verbosity = .performance
            Log.info("Extra verbose mode has been activated.")
        }

        if CommandLine.arguments.contains("--cli") {
            logger.verbosity = .cli
            Log.info("Extra CLI mode has been activated via --cli flag.")
        }

        if state.container.filesystem.fileExists("~/.config/phpmon/verbose") {
            logger.verbosity = .cli
            Log.info("Extra CLI mode is on (`~/.config/phpmon/verbose` exists).")
        }

        if !isRunningSwiftUIPreview {
            Log.separator(as: .info)
            Log.info("PHP MONITOR by Nico Verbruggen")
            Log.info("Version \(App.version)")
            Log.separator(as: .info)
        }

        // Initialize the crash reporter
        CrashReporter.initialize()

        // Set up final singletons
        self.valet = Valet.shared
        self.brew = Brew.shared
        super.init()
    }

    static func initializeTestingProfile(_ path: String) {
        Log.info("The configuration with path `\(path)` is being requested...")
        // Clear for PHP Guard
        Stats.clearCurrentGlobalPhpVersion()
        // Load the configuration file
        TestableConfiguration.loadFrom(path: path).apply()
    }

    // MARK: - Lifecycle

    /**
     When the application has finished launching, we'll want to set up
     the user notification center permissions, and kickoff the menu
     startup procedure.
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Prevent previews from kicking off a costly boot
        if isRunningSwiftUIPreview {
            return
        }

        // Make sure notifications will work
        setupNotifications()

        // Start with the regular busy icon
        MainMenu.shared.setStatusBar(image: NSImage.statusBarIcon)

        Task { // Make sure the menu performs its initial checks
            await Startup.check(App.shared.container)
        }
    }

    // MARK: - Menu Items

    @IBOutlet weak var menuItemSites: NSMenuItem!

    /**
     Ensure relevant menu items in the main menu bar (not the pop-up menu)
     are disabled or hidden when needed.
     */
    public func configureMenuItems(standalone: Bool) {
        if standalone {
            menuItemSites.isHidden = true
        }
    }
}
