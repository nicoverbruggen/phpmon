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

    // MARK: - Entry Point

    /// `NSApplication.delegate` does not retain its delegate; this keeps it alive.
    private static var mainDelegate: AppDelegate?

    /**
     The app starts without a main storyboard: the delegate is created here,
     the main menu bar is built in code, and control is handed to AppKit.
     */
    static func main() {
        let app = NSApplication.shared

        let delegate = AppDelegate()
        mainDelegate = delegate
        app.delegate = delegate

        app.mainMenu = AppMenu.build(actionsTarget: delegate)

        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
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

        // Resolve the user's PATH eagerly, but on the concurrent pool: `RealShell`
        // resolves it lazily by spawning an interactive shell (up to seconds), which
        // must never block the main actor. This runs after the (DEBUG) configuration
        // profile may have swapped in fakes, so tests never spawn a real shell here.
        // Consumers that race this warm-up serialize on the shell's internal lock.
        Task { [shell = state.container.shell!] in
            await offMain { _ = shell.PATH }
        }

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
     When the application has finished launching, kick off the menu startup procedure.

     Notification permissions are only requested after the app has already completed one
     successful boot in the past. This avoids showing the macOS notification prompt during
     first-run onboarding or failed startup attempts.
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Prevent previews from kicking off a costly boot
        if isRunningSwiftUIPreview {
            return
        }

        #if DEBUG
        // Structural dump of the main menu, used to verify parity during the
        // storyboard → code migration of the menu bar.
        if ProcessInfo.processInfo.arguments.contains("--dump-main-menu") {
            // Written to stderr: unlike stdout, it is unbuffered when piped.
            func emit(_ line: String) {
                FileHandle.standardError.write(Data((line + "\n").utf8))
            }

            func dump(_ menu: NSMenu, indent: String) {
                for item in menu.items {
                    if item.isSeparatorItem {
                        emit("\(indent)---")
                        continue
                    }
                    let action = item.action.map(String.init(describing:)) ?? "nil"
                    let mask = item.keyEquivalentModifierMask.rawValue
                    emit("\(indent)\(item.title) | key=\(item.keyEquivalent) | mask=\(mask) "
                         + "| action=\(action) | tag=\(item.tag) | enabled=\(item.isEnabled) "
                         + "| hidden=\(item.isHidden)")
                    if let submenu = item.submenu {
                        dump(submenu, indent: indent + "  ")
                    }
                }
            }

            if let mainMenu = NSApp.mainMenu {
                emit("=== MAIN MENU DUMP ===")
                dump(mainMenu, indent: "")
                emit("=== END MENU DUMP ===")
            }
        }
        #endif

        // Set up the notification center delegate immediately.
        setupNotifications()

        // Returning users can be asked for notification permissions during launch.
        if Stats.successfulLaunchCount > 0 {
            NotificationPermission.request()
        }

        // Start with the regular busy icon
        MainMenu.shared.setStatusBar(image: NSImage.statusBarIcon)

        Task { // Make sure the menu performs its initial checks
            await Startup.check(App.shared.container)
        }
    }

    // MARK: - Menu Items

    /**
     Ensure relevant menu items in the main menu bar (not the pop-up menu)
     are disabled or hidden when needed.
     */
    public func configureMenuItems(standalone: Bool) {
        AppMenu.sitesMenuItem?.isHidden = standalone
    }
}
