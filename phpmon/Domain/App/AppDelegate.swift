//
//  AppDelegate.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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

    // MARK: - Initializer

    /**
     When the application initializes, create all singletons.
     */
    override init() {
        logger.verbosity = .info

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
        self.watchHomebrewBinFolder()
        /*
        // Make sure notifications will work
        setupNotifications()
        Task { // Make sure the menu performs its initial checks
            await paths.loadUser()
            await menu.startup()
        }
        */
    }

    func watchHomebrewBinFolder() {
        Log.info("Watching Homebrew's bin folder")
        FSWatch2.shared = FSWatch2(
            for: URL(fileURLWithPath: Paths.binPath),
            eventMask: .all,
            onChange: {
                print("Something has changed")
            }
        )
    }
}

class FSWatch2 {
    public static var shared: FSWatch2! = nil

    let queue = DispatchQueue(label: "FSWatch2Queue", attributes: .concurrent)

    var lastUpdate: TimeInterval?
    var linked: Bool

    private var fileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    internal let url: URL

    init(for url: URL, eventMask: DispatchSource.FileSystemEvent, onChange: () -> Void) {
        self.url = url

        self.linked = FileSystem.fileExists(Paths.php)
        print("Initial PHP linked state: \(linked)")

        fileDescriptor = open(url.path, O_EVTONLY)

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: eventMask,
            queue: self.queue
        )

        dispatchSource?.setEventHandler(handler: {
            let distance = self.lastUpdate?.distance(to: Date().timeIntervalSince1970)

            if distance == nil || distance != nil && distance! > 1.00 {
                print("FS event fired, checking in 1s, no duplicate FS events will be acted upon")

                self.lastUpdate = Date().timeIntervalSince1970

                Task {
                    await delay(seconds: 1)

                    let newLinked = FileSystem.fileExists(Paths.php)

                    if newLinked != self.linked {
                        self.linked = newLinked

                        Log.info("The status of the PHP binary has changed!")

                        if newLinked {
                            Log.info("php is linked")
                        } else {
                            Log.info("php is not linked")
                        }
                    }
                }
            }
        })

        dispatchSource?.setCancelHandler(handler: { [weak self] in
            guard let self = self else { return }

            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.dispatchSource = nil
        })

        dispatchSource?.resume()
    }

    deinit {
        print("deallocing watcher")
    }
}
