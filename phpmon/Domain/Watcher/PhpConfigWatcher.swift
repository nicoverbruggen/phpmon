//
//  FolderWatcher.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpConfigWatcher {

    let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)

    let url: URL

    var didChange: ((URL) -> Void)?

    var lastUpdate: TimeInterval?

    var watchers: [FSWatcher] = []

    init(for url: URL) {
        if FileSystem is TestableFileSystem {
            fatalError("""
                PhpConfigWatcher is not compatible with testable FS! "
                You are not allowed to instantiate these while using a testable FS.
            """)
        }

        self.url = url

        // Add a watcher for php.ini
        self.addWatcher(for: self.url.appendingPathComponent("php.ini"), eventMask: .write)

        // Add a watcher for conf.d (in case a new file is added or a file is deleted)
        // This watcher, when triggered, will restart all watchers
        self.addWatcher(for: self.url.appendingPathComponent("conf.d"), eventMask: .all, behaviour: .reloadsWatchers)

        // Scan the conf.d folder for .ini files, and add a watcher for each file
        let enumerator = FileManager.default.enumerator(atPath: self.url.appendingPathComponent("conf.d").path)
        let filePaths = enumerator?.allObjects as! [String]

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
        behaviour: FSWatcherBehaviour = .reloadsMenu
    ) {
        if !FileSystem.anyExists(url.path) {
            Log.warn("No watcher was created for \(url.path) because the requested file does not exist.")
            return
        }

        let watcher = FSWatcher(for: url, eventMask: eventMask, parent: self, behaviour: behaviour)
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

enum FSWatcherBehaviour {
    case reloadsMenu
    case reloadsWatchers
}

class FSWatcher {

    private var parent: PhpConfigWatcher!

    private var monitoredFolderFileDescriptor: CInt = -1

    private var folderMonitorSource: DispatchSourceFileSystemObject?

    let url: URL

    init(
        for url: URL,
        eventMask: DispatchSource.FileSystemEvent,
        parent: PhpConfigWatcher,
        behaviour: FSWatcherBehaviour = .reloadsMenu
    ) {
        self.url = url
        self.parent = parent
        self.startMonitoring(eventMask, behaviour: behaviour)
    }

    func startMonitoring(
        _ eventMask: DispatchSource.FileSystemEvent,
        behaviour: FSWatcherBehaviour
    ) {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }

        // Open the file or folder referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor,
            eventMask: eventMask,
            queue: parent.folderMonitorQueue
        )

        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            // The default behaviour is to reload the menu
            switch behaviour {
            case .reloadsMenu:
                // Default behaviour: reload the menu items
                self?.parent.didChange?(self!.url)
            case .reloadsWatchers:
                // Alternative behaviour: reload all watchers
                App.shared.handlePhpConfigWatcher(forceReload: true)
            }
        }

        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.monitoredFolderFileDescriptor)
            self.monitoredFolderFileDescriptor = -1
            self.folderMonitorSource = nil
        }

        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }

    func stopMonitoring() {
        folderMonitorSource?.cancel()
        self.parent = nil
    }
}
