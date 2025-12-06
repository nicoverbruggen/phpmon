//
//  FSNotifier.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/01/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

actor FSNotifier {

    // MARK: Variables

    /** The URL of the file or folder that is being observed. */
    nonisolated let url: URL

    /** Whether responding to events is currently on hold. */
    private(set) var isSuspended = false

    // MARK: Internal Variables

    /** The queue that is used for the `dispatchSource`. */
    private nonisolated let queue: DispatchQueue

    /** An open file or folder required for observation. */
    private nonisolated(unsafe) var fileDescriptor: CInt = -1

    /** A dispatch source that monitors events associated with a file or folder. */
    private nonisolated(unsafe) var dispatchSource: DispatchSourceFileSystemObject?

    // MARK: Methods

    init(
        for url: URL,
        eventMask: DispatchSource.FileSystemEvent,
        queue: DispatchQueue? = nil,
        onChange: @escaping () -> Void
    ) {
        self.url = url
        self.queue = queue ?? DispatchQueue(label: "com.nicoverbruggen.phpmon.fs_notifier")

        fileDescriptor = open(url.path, O_EVTONLY)

        guard fileDescriptor >= 0 else {
            Log.err("Failed to open file descriptor for \(url.path), this notifier will not work.")
            return
        }

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: eventMask,
            queue: self.queue
        )

        dispatchSource?.setEventHandler(handler: { [weak self] in
            Task { [weak self] in
                guard let self = self else { return }

                // If our notifier is suspended, don't fire
                guard await !self.isSuspended else { return }

                // If our notifier is not suspended, fire
                onChange()
            }
        })

        dispatchSource?.setCancelHandler(handler: {
            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.dispatchSource = nil
        })

        dispatchSource?.resume()
    }

    /** Suspends responding to filesystem events. This does not stop events from being observed! */
    func suspend() async {
        self.isSuspended = true
        Log.perf("FSNotifier for \(self.url.path) has been suspended.")
    }

    /** Resumes responding to filesystem events. */
    func resume() async {
        self.isSuspended = false
        Log.perf("FSNotifier for \(self.url.path) has been resumed.")
    }

    /** Terminates the file monitor, which will cause `deinit` to fire. */
    nonisolated func terminate() {
        dispatchSource?.cancel()
    }

    nonisolated deinit {
        Log.perf("deinit: FSNotifier @ \(self.url.path)")
    }

}
