//
//  StateManager.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

class App {

    // MARK: Static Vars

    /** The static app instance. Accessible at any time. */
    static let shared = App()

    /** Use to determine whether a loaded testable configuration is being used. */
    static var hasLoadedTestableConfiguration: Bool = false

    /** The display name of the app, as declared in Info.plist. */
    static var displayName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as! String
    }

    /** Retrieve the version number from the main info dictionary, Info.plist. */
    static var version: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return "\(version) (\(build))"
    }

    /** Just the bundle version (build). */
    static var bundleVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }

    /** Just the version number. */
    static var shortVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }

    /** Just the bundle name. */
    static var identifier: String {
        Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
    }

    /** The system architecture. Paths differ based on this value. */
    static var architecture: String {
        if fakeArchitecture != nil { return fakeArchitecture! }

        var systeminfo = utsname()
        uname(&systeminfo)
        let machine = withUnsafeBytes(of: &systeminfo.machine) { bufPtr -> String in
            let data = Data(bufPtr)
            if let lastIndex = data.lastIndex(where: {$0 != 0}) {
                return String(data: data[0...lastIndex], encoding: .isoLatin1)!
            } else {
                return String(data: data, encoding: .isoLatin1)!
            }
        }
        return machine
    }

    static var macVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /**
     A fake architecture.
     When set, the real machine's system architecture is not used,
     but this fixed value is used instead.
     */
    static var fakeArchitecture: String?

    // MARK: Variables

    /**
     The dependency container.
     This is supposed to be injected, so direct access is discouraged.
     */
    var container: Container = Container()

    /** The list of preferences that are currently active. */
    var preferences: [PreferenceName: Bool]!

    /** The window controller of the currently active preferences window. */
    var preferencesWindowController: PreferencesWindowController?

    /** The window controller of the currently active site list window. */
    var domainListWindowController: DomainListWindowController?

    /** The window controller of the onboarding window. */
    var onboardingWindowController: OnboardingWindowController?

    /** The window controller of the config manager window. */
    var phpConfigManagerWindowController: PhpConfigManagerWindowController?

    /** The window controller of the warnings window. */
    var phpDoctorWindowController: PhpDoctorWindowController?

    /** The window controller of the PHP version manager window. */
    var phpVersionManagerWindowController: PhpVersionManagerWindowController?

    /** The window controller of the PHP extension manager window. */
    var phpExtensionManagerWindowController: PhpExtensionManagerWindowController?

    /** List of detected (installed) applications that PHP Monitor can work with. */
    var detectedApplications: [Application] = []

    /** Timer that will periodically reload info about the user's PHP installation. */
    var timer: Timer?

    // MARK: - Global Hotkey

    /**
     The shortcut the user has requested.
     */
    var shortcutHotkey: HotKey? {
        didSet {
            setupGlobalHotkeyListener()
        }
    }

    // MARK: - Activation Policy

    /**
     Variable that keeps track of which windows are currently open.
     (Please note that window controllers remain open in memory once opened.)
     
     When this list is updated, the app activation policy is re-evaluated.
     The app activation policy dictates how the app runs
     (as a normal app or as a toolbar app).
     */
    var openWindows: [String] = []

    // MARK: - App Watchers

    /** Individual filesystem watchers, which are, i.e. responsible for watching the Homebrew folders. */
    var watchers: [String: FSNotifier] = [:]

    /** Individual debouncers for filesystem watchers. */
    var debouncers: [String: Debouncer] = [:]

    /** 
     The `ConfigWatchManager` is responsible for watching the `.ini` files and the `.conf.d` folder.
     This manager object can immediately start or stop all watchers (or pause them) all at once.
     */
    var watchManager: ConfigWatchManager!
}
