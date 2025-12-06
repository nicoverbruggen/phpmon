//
//  HomebrewWatchManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor HomebrewWatchManager: Suspendable {

    // MARK: Public API

    /**
     Prepares the Homebrew watcher. This allows PHP Monitor to quickly respond to
     external `brew` changes executed by the user.

     - Important: This manager remains nil when a `TestableFileSystem` is in place.
     */
    @MainActor
    public static func prepare() async {
        let container = App.shared.container

        if container.filesystem is TestableFileSystem {
            Log.warn("HomebrewWatchManager is disabled when using a testable filesystem.")
            return
        }

        let manager = HomebrewWatchManager(
            for: URL(fileURLWithPath: container.paths.binPath),
            debounceInterval: 5.0
        )

        await manager.setupWatcher()

        App.shared.homebrewWatchManager = manager
    }

    // MARK: - Instance variables

    /**
     The underlying `FSNotifier` which will respond to filesystem events.
     */
    private var watcher: FSNotifier?

    /**
     The debouncer, responsible for ensuring events stop firing before
     finally responding to changes in `homebrew/bin`.
     */
    private var debouncer: Debouncer

    /**
     The URL of the `homebrew/bin` path, that we will be watching, too.
     */
    nonisolated let url: URL

    /**
     The interval for the debounce. Prevents bulk changes from triggering
     too many fired events.
     */
    nonisolated let debounceInterval: TimeInterval

    // MARK: - Lifecycle

    init(for url: URL, debounceInterval: TimeInterval = 5.0) {
        if App.shared.container.filesystem is TestableFileSystem {
            fatalError("""
                HomebrewWatchManager is currently incompatible with a testable filesystem!
                You are not allowed to instantiate these while using a testable filesystem.
            """)
        }

        self.url = url
        self.debounceInterval = debounceInterval
        self.debouncer = Debouncer()
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

    // MARK: - Internal Methods

    /**
     Sets up the watcher, assuming one does not exist.
     The target directory must exist.
     */
    private func setupWatcher() {
        // Guard against double setup
        assert(watcher == nil, "setupWatcher() called when watcher already exists")

        // Ensure that the target directory exists
        if !App.shared.container.filesystem.anyExists(url.path) {
            Log.warn("No watcher was created for \(url.path) because the requested directory does not exist.")
            return
        }

        // Create a new FSNotifier which will respond to all events.
        // If files are created, removed, etc. in this `homebrew/bin` folder, the handler will fire.
        self.watcher = FSNotifier(for: url, eventMask: .all) { [weak self] in
            guard let self = self else { return }

            Task {
                await self.onHomebrewPhpModification()
            }
        }

        Log.perf("A watcher exists for Homebrew binaries at: \(url.relativePath)")
    }

    /**
     Reloads PHP versions and refreshes the active PHP installation if any changes
     are made to Homebrew binaries. Usually external changes to packages will trigger this.

     As such, PHP Monitor will check if anything has changed with PHP.
     */
    private func onHomebrewPhpModification() async {
        await debouncer.debounce(for: debounceInterval) { [weak self] in
            guard let self = self else { return }
            Log.info("No changes in `\(self.url.path)` occurred for \(self.debounceInterval) seconds. Reloading now.")

            // We reload the PHP versions in the background
            await App.shared.container.phpEnvs.reloadPhpVersions()

            // Finally, refresh the active installation
            await MainMenu.shared.refreshActiveInstallation()
        }
    }

    // MARK: - Suspendable Protocol

    /**
     Performs a particular action while suspending the Homebrew watcher,
     until the task is completed.

     Any operations that cause Homebrew to perform tasks (installing,
     updating, removing packages) should be wrapped in this helper method,
     to prevent the app from doing duplicate work.
     */
    public static func withSuspended<T>(_ action: () async throws -> T) async rethrows -> T {
        guard let manager = App.shared.homebrewWatchManager else {
            // If there's no manager, run the task as-is
            return try await action()
        }

        // Suspend, execute the action, and resume
        return try await manager.withSuspended(action)
    }

    /**
     Suspends the `HomebrewWatchManager`.
     This prevents any changes to `/homebrew/bin` from causing events to fire.
     */
    func suspend() async {
        await watcher?.suspend()
        await debouncer.cancel()
    }

    /**
     Resumes the `HomebrewWatchManager`.
     Any changes to `/homebrew/bin` are picked up again.
     */
    func resume() async {
        await watcher?.resume()
    }
}
