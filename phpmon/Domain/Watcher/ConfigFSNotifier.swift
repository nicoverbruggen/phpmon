//
//  ConfigFSNotifier.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/10/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
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
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }

        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor,
            eventMask: eventMask,
            queue: parent.folderMonitorQueue
        )

        folderMonitorSource?.setEventHandler { [weak self] in
            if behaviour == .reloadsWatchers
                && !ConfigWatchManager.ignoresModificationsToConfigValues {
                // Reload all configuration watchers
                return App.shared.handlePhpConfigWatcher(forceReload: true)
            }

            self?.parent.didChange?(self!.url)
        }

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
