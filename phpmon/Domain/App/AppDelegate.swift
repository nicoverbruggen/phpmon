//
//  AppDelegate.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Variables

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
     The PhpEnv singleton that handles PHP version
     detection, as well as switching. It is initialized
     when the app is ready and passed all checks.
     */
    var phpEnvironment: PhpEnv! = nil

    /**
     The logger is responsible for different levels of logging.
     You can tweak the verbosity in the `init` method here.
     */
    var logger = Log.shared

    /**

     */
    var watchers: [FSNotifier.Kind: FSNotifier] = [:]

    // MARK: - Initializer

    /**
     When the application initializes, create all singletons.
     */
    override init() {
        #if DEBUG
        logger.verbosity = .performance

        if let profile = CommandLine.arguments.first(where: { $0.matches(pattern: "--configuration:*") }) {
            Self.initializeTestingProfile(profile.replacingOccurrences(of: "--configuration:", with: ""))
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

        if FileSystem.fileExists("~/.config/phpmon/verbose") {
            logger.verbosity = .cli
            Log.info("Extra CLI mode is on (`~/.config/phpmon/verbose` exists).")
        }

        Log.separator(as: .info)
        Log.info("PHP MONITOR by Nico Verbruggen")
        Log.info("Version \(App.version)")
        Log.separator(as: .info)

        self.state = App.shared
        self.menu = MainMenu.shared
        self.paths = Paths.shared
        self.valet = Valet.shared
        super.init()
    }

    func initializeSwitcher() {
        self.phpEnvironment = PhpEnv.shared
    }

    static func initializeTestingProfile(_ path: String) {
        Log.info("The configuration with path `\(path)` is being requested...")
        TestableConfiguration.loadFrom(path: path).apply()
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
        // Make sure the watchers are set up
        // TODO: Move to after startup
        self.watchHomebrewBinFolder()

        Task { // Make sure the menu performs its initial checks
            await paths.loadUser()
            await menu.startup()
        }
    }

    func watchHomebrewBinFolder() {
        self.watchers[.homebrewLocks] = FSNotifier(
            for: URL(fileURLWithPath: Paths.binPath),
            eventMask: .all,
            onChange: {
                // Removing requires termination and then removing reference
                // self.watchers[.homebrewLocks]?.terminate()
                // self.watchers[.homebrewLocks] = nil
            }
        )
    }
}
