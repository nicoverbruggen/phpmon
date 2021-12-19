//
//  FolderWatcher.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpConfigWatcher {
    
    let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    
    let url: URL
    
    var didChange: ((URL) -> Void)?
    
    var lastUpdate: TimeInterval? = nil
    
    var watchers: [FSWatcher] = []
    
    init(for url: URL) {
        self.url = url
        
        // Add a watcher for php.ini
        self.addWatcher(for: self.url.appendingPathComponent("php.ini"), eventMask: .write)
        
        // Add a watcher for conf.d (in case a new file is added or a file is deleted)
        // TODO: Make sure that the contents of the conf.d folder is checked each time... this might mean
        // that watchers are due for deletion / need to be created
        self.addWatcher(for: self.url.appendingPathComponent("conf.d"), eventMask: .all)
        
        // Scan the conf.d folder for .ini files, and add a watcher for each file
        let enumerator = FileManager.default.enumerator(atPath: self.url.appendingPathComponent("conf.d").path)
        let filePaths = enumerator?.allObjects as! [String]
        
        // Loop over the .ini files that we discovered
        filePaths.filter { $0.contains(".ini") }.forEach { (file) in
            // Add a watcher for each file we have discovered
            self.addWatcher(for: self.url.appendingPathComponent("conf.d/\(file)"), eventMask: .write)
        }
        
        print("A watcher exists for the following config paths:")
        for watcher in self.watchers {
            print(watcher.url)
        }
    }
    
    func addWatcher(for url: URL, eventMask: DispatchSource.FileSystemEvent) {
        let watcher = FSWatcher(for: url, eventMask: eventMask, parent: self)
        self.watchers.append(watcher)
    }
    
    func disable() {
        print("Turning off existing watchers...")
        self.watchers.forEach { (watcher) in
            watcher.stopMonitoring()
        }
    }
    
    deinit {
        print("An existing config watcher has been deinitialized.")
    }
    
}

class FSWatcher {
    
    private var parent: PhpConfigWatcher!
    
    private var monitoredFolderFileDescriptor: CInt = -1
    
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    
    let url: URL
    
    init(for url: URL, eventMask: DispatchSource.FileSystemEvent, parent: PhpConfigWatcher) {
        self.url = url
        self.parent = parent
        self.startMonitoring(eventMask)
    }

    func startMonitoring(_ eventMask: DispatchSource.FileSystemEvent) {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        
        // Open the file or folder referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: eventMask, queue: parent.folderMonitorQueue)
        
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.parent.didChange?(self!.url)
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
