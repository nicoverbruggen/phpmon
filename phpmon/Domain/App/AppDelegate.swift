//
//  AppDelegate.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import UserNotifications

@main
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
        // Log information about the app
        if !isRunningSwiftUIPreview {
            Log.separator(as: .always)
            Log.always("PHP MONITOR by Nico Verbruggen")
            Log.always("Version \(App.version)")
            Log.separator(as: .always)
        }

        // Initialize the crash reporter
        CrashReporter.initialize()

        // Prepare the container with the defaults
        // (the container exists at this point, but is not yet bound)
        self.state = App.shared

        #if DEBUG
        // Apply system context overrides (architecture, shell) before binding,
        // since bind() reads systemContext to determine paths and shell config
        CLI.applySystemContext()
        #endif

        // ========================
        // (!) CONTAINER IS BOUND
        // ========================
        self.state.container.bind()

        #if DEBUG
        logger.verbosity = .performance
        Log.info("Extra verbose mode is enabled by default on DEBUG builds.")

        // No matter what, clear PHP Guard if it's a debug build
        Stats.clearCurrentGlobalPhpVersion()

        // Load testable configuration profile (if provided via launch argument)
        CLI.loadConfigurationProfile()
        #endif

        // Check if any command line arguments need to be acted upon
        CLI.checkCommandLineArguments()

        if state.container.filesystem.fileExists("~/.config/phpmon/verbose") {
            Log.shared.verbosity = .cli
            Log.info("Extra CLI mode is on (`~/.config/phpmon/verbose` exists).")
        }

        Log.info("Using \(App.displayName) \(App.version) on macOS \(App.macVersion).")

        // Set up final singletons
        self.valet = Valet.shared
        self.brew = Brew.shared
        super.init()
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
