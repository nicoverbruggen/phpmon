//
//  ConfigFSNotifier.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/10/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class ConfigFSNotifier {

    enum Behaviour {
        case reloadsMenu
        case reloadsWatchers
    }

    private var parent: ConfigWatchManager!

    private var monitoredFolderFileDescriptor: CInt = -1

    private var folderMonitorSource: DispatchSourceFileSystemObject?

    let url: URL

    init(
        for url: URL,
        eventMask: DispatchSource.FileSystemEvent,
        parent: ConfigWatchManager,
        behaviour: ConfigFSNotifier.Behaviour = .reloadsMenu
    ) {
        self.url = url
        self.parent = parent
        self.startMonitoring(eventMask, behaviour: behaviour)
    }

    func startMonitoring(
        _ eventMask: DispatchSource.FileSystemEvent,
        behaviour: ConfigFSNotifier.Behaviour
    ) {
        // Ensure our starting state is correct, we may already be monitoring!
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }

        // We'll try to open a file descriptor and validate it
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)

        // If our file descriptor here is still -1, there may have been an issue and we abort
        guard monitoredFolderFileDescriptor >= 0 else {
            Log.err("Failed to open file descriptor for \(url.path), not monitoring.")
            return
        }

        // Set the source (with proper file descriptor, event mask and using the right queue)
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor,
            eventMask: eventMask,
            queue: parent.folderMonitorQueue
        )

        // Set the event handler (fires depending on the event mask)
        folderMonitorSource?.setEventHandler { [weak self] in
            if behaviour == .reloadsWatchers
                && !ConfigWatchManager.ignoresModificationsToConfigValues {
                // Reload all configuration watchers
                return App.shared.handlePhpConfigWatcher(forceReload: true)
            }

            if let url = self?.url {
                self?.parent.didChange?(url)
            }
        }

        // Cancellation handler, fired when we stop monitoring files
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }

            close(self.monitoredFolderFileDescriptor)
            self.monitoredFolderFileDescriptor = -1
            self.folderMonitorSource = nil
        }

        folderMonitorSource?.resume()
    }

    func stopMonitoring() {
        folderMonitorSource?.cancel()
        self.parent = nil
    }
}
