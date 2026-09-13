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

        // Replacing an existing manager would orphan its FSNotifier (the notifier's
        // cancel handler keeps it alive until cancelled), so tear it down first.
        if let existing = App.shared.homebrewWatchManager {
            App.shared.homebrewWatchManager = nil
            await existing.disable()
        }

        // Read the (Sendable) filesystem here on the main actor and hand it to the
        // actor, so the actor never has to touch main-actor `App`/`Container` state.
        let manager = HomebrewWatchManager(
            for: URL(fileURLWithPath: container.paths.binPath),
            filesystem: container.filesystem,
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

    /**
     The filesystem is a Sendable, nonisolated leaf dependency, captured at
     construction so the actor can perform existence checks off the main actor.
     */
    nonisolated private let filesystem: FileSystemProtocol

    // MARK: - Lifecycle

    init(for url: URL, filesystem: FileSystemProtocol, debounceInterval: TimeInterval = 5.0) {
        if filesystem is TestableFileSystem {
            fatalError("""
                HomebrewWatchManager is currently incompatible with a testable filesystem!
                You are not allowed to instantiate these while using a testable filesystem.
            """)
        }

        self.url = url
        self.filesystem = filesystem
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
        if !filesystem.anyExists(url.path) {
            Log.warn("No watcher was created for \(url.path) because the requested directory does not exist.")
            return
        }

        // Create a new FSNotifier which will respond to all events.
        // If files are created, removed, etc. in this `homebrew/bin` folder, the handler will fire.
        self.watcher = FSNotifier(for: url, eventMaskRawValue: DispatchSource.FileSystemEvent.all.rawValue) { [weak self] in
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
            await App.shared.container.phpEnvs.detectPhpVersions()

            // Finally, refresh the active installation
            await MainMenu.shared.refreshActiveInstallation()
        }
    }

    /**
     Permanently disables this manager: cancels any pending debounced work and
     terminates the underlying `FSNotifier` (which breaks the notifier's deliberate
     keep-alive cycle so both objects can deinit).
     */
    func disable() async {
        await debouncer.cancel()
        watcher?.terminate()
        watcher = nil
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
        guard let manager = await App.shared.homebrewWatchManager else {
            // If there's no manager, run the task as-is
            return try await action()
        }

        // `action` runs here in the caller's isolation domain; only `suspend()`/`resume()`
        // hop onto the watcher actor. This keeps a (main-actor) `action` closure from being
        // transferred into the actor, which would be a data-race error.
        await manager.suspend()
        do {
            let result = try await action()
            await manager.resume()
            return result
        } catch {
            await manager.resume()
            throw error
        }
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
