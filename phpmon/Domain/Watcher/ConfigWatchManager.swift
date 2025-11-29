//
//  ConfigWatchManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor ConfigWatchManager {

    enum Behaviour {
        case reloadsMenu
        case reloadsWatchers
    }

    // MARK: Global state (applicable to ALL watchers)

    // TODO: Rework into suspend mechanism (like `HomebrewWatchManager`) to avoid issues with concurrency
    static var ignoresModificationsToConfigValues: Bool = false

    // MARK: Static methods

    /**
     Handles the PHP configuration file(s) manager lifecycle.

     Creates a new manager w/ watchers if needed, or updates the watchers if the current
     PHP version has changed. This will be called whenever the PHP version changes, or
     when the application first starts.

     - Important: This manager remains nil when a `TestableFileSystem` is in place.
     */
    @MainActor
    public static func handleWatcher(forceReload: Bool = false) async {
        let container = App.shared.container

        if container.filesystem is TestableFileSystem {
            Log.warn("ConfigWatchManager is disabled when using a testable filesystem.")
            return
        }

        guard let install = container.phpEnvs.phpInstall else {
            Log.info("It appears as if no PHP installation is currently active.")
            Log.info("The config watch manager is disabled until a PHP install is active.")
            return
        }

        let url = URL(fileURLWithPath: "\(container.paths.etcPath)/php/\(install.version.short)")

        // Create watcher if missing
        guard let manager = App.shared.configWatchManager else {
            let manager = ConfigWatchManager(for: url)
            await manager.setupWatchers()
            App.shared.configWatchManager = manager
            return
        }

        // Update existing watcher if needed
        if await manager.url != url {
            // URL changed - update to different PHP version
            await manager.updateUrl(to: url)
        } else if forceReload {
            // Same URL - just reload watchers (e.g., conf.d files added/removed)
            await manager.reloadWatchers()
        }
    }

    // MARK: Instance variables

    private var watchers: [FSNotifier] = []
    private var debouncer: Debouncer

    private(set) var url: URL
    nonisolated private let debounceInterval: TimeInterval

    // MARK: Methods

    init(for url: URL, debounceInterval: TimeInterval = 0.75) {
        if App.shared.container.filesystem is TestableFileSystem {
            fatalError("""
                ConfigWatchManager is currently incompatible with a testable filesystem!"
                You are not allowed to instantiate these while using a testable filesystem.
            """)
        }

        self.url = url
        self.debounceInterval = debounceInterval
        self.debouncer = Debouncer()
    }

    func setupWatchers() {
        // Guard against double setup
        assert(watchers.isEmpty, "setupWatchers() called when watchers already exist")

        // Add a watcher for php.ini
        self.addWatcher(for: self.url.appendingPathComponent("php.ini"), eventMask: .write)

        // Add a watcher for conf.d (in case a new file is added or a file is deleted)
        // This watcher, when triggered, will restart all watchers
        self.addWatcher(for: self.url.appendingPathComponent("conf.d"), eventMask: .all, behaviour: .reloadsWatchers)

        // Scan the conf.d folder for .ini files, and add a watcher for each file
        let filePaths = FileManager.default.enumerator(
            atPath: self.url.appendingPathComponent("conf.d").path
        )?.allObjects as? [String]

        // Only loop over the discovered files if applicable
        if let filePaths {
            // Loop over the .ini files that we discovered
            filePaths.filter { $0.contains(".ini") }.forEach { (file) in
                // Add a watcher for each file we have discovered
                self.addWatcher(for: self.url.appendingPathComponent("conf.d/\(file)"), eventMask: .write)
            }
        }

        Log.perf("A watcher exists for the following config paths:")
        Log.perf(self.watchers.map({ watcher in
            return watcher.url.relativePath
        }))
    }

    private func clearWatchers() {
        for watcher in self.watchers {
            watcher.terminate()
        }
        self.watchers.removeAll()
    }

    func reloadWatchers() {
        Log.perf("Reloading configuration watchers...")
        clearWatchers()
        setupWatchers()
    }

    func updateUrl(to newUrl: URL) {
        Log.perf("Updating watcher URL from \(self.url.path) to \(newUrl.path)...")
        clearWatchers()
        self.url = newUrl
        setupWatchers()
    }

    private func handleConfigChange(at url: URL) async {
        await debouncer.debounce(for: debounceInterval) {
            Log.perf("Config file changed at \(url.path), debounce completed. Refreshing menu...")
            Task { @MainActor in MainMenu.shared.reloadPhpMonitorMenuInBackground() }
        }
    }

    private func addWatcher(
        for url: URL,
        eventMask: DispatchSource.FileSystemEvent,
        behaviour: Behaviour = .reloadsMenu
    ) {
        if !App.shared.container.filesystem.anyExists(url.path) {
            Log.warn("No watcher was created for \(url.path) because the requested file does not exist.")
            return
        }

        let watcher = FSNotifier(for: url, eventMask: eventMask) { [weak self] in
            guard let self = self else { return }

            Task {
                if behaviour == .reloadsWatchers
                    && !ConfigWatchManager.ignoresModificationsToConfigValues {
                    // Reload all configuration watchers on this manager
                    await self.reloadWatchers()
                    return
                }

                await self.handleConfigChange(at: url)
            }
        }
        self.watchers.append(watcher)
    }

    func disable() async {
        Log.perf("Turning off all individual existing watchers...")
        await debouncer.cancel()
        clearWatchers()
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

}
