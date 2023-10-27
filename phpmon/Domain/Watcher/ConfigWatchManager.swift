//
//  ConfigWatchManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class ConfigWatchManager {

    static var ignoresModificationsToConfigValues: Bool = false

    let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)

    let url: URL
    var didChange: ((URL) -> Void)?
    var lastUpdate: TimeInterval?

    var watchers: [ConfigFSNotifier] = []

    init(for url: URL) {
        if FileSystem is TestableFileSystem {
            fatalError("""
                ConfigWatchManager is currently incompatible with a testable filesystem!"
                You are not allowed to instantiate these while using a testable filesystem.
            """)
        }

        self.url = url

        // Add a watcher for php.ini
        self.addWatcher(for: self.url.appendingPathComponent("php.ini"), eventMask: .write)

        // Add a watcher for conf.d (in case a new file is added or a file is deleted)
        // This watcher, when triggered, will restart all watchers
        self.addWatcher(for: self.url.appendingPathComponent("conf.d"), eventMask: .all, behaviour: .reloadsWatchers)

        // Scan the conf.d folder for .ini files, and add a watcher for each file
        let filePaths = FileManager.default.enumerator(
            atPath: self.url.appendingPathComponent("conf.d").path
        )?.allObjects as! [String]

        // Loop over the .ini files that we discovered
        filePaths.filter { $0.contains(".ini") }.forEach { (file) in
            // Add a watcher for each file we have discovered
            self.addWatcher(for: self.url.appendingPathComponent("conf.d/\(file)"), eventMask: .write)
        }

        Log.perf("A watcher exists for the following config paths:")
        Log.perf(self.watchers.map({ watcher in
            return watcher.url.relativePath
        }))
    }

    func addWatcher(
        for url: URL,
        eventMask: DispatchSource.FileSystemEvent,
        behaviour: ConfigFSNotifier.Behaviour = .reloadsMenu
    ) {
        if !FileSystem.anyExists(url.path) {
            Log.warn("No watcher was created for \(url.path) because the requested file does not exist.")
            return
        }

        let watcher = ConfigFSNotifier(for: url, eventMask: eventMask, parent: self, behaviour: behaviour)
        self.watchers.append(watcher)
    }

    func disable() {
        Log.perf("Turning off all individual existing watchers...")
        self.watchers.forEach { (watcher) in
            watcher.stopMonitoring()
        }
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

}
