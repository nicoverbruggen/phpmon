//
//  FSNotifier.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/01/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class FSNotifier {

    public static var shared: FSNotifier! = nil

    // MARK: Public variables

    let queue = DispatchQueue(label: "com.nicoverbruggen.phpmon.fs_notifier")
    let url: URL

    // MARK: Private variables

    private var fileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    // MARK: Methods

    init(for url: URL, eventMask: DispatchSource.FileSystemEvent, onChange: @escaping () -> Void) {
        self.url = url

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

        dispatchSource?.setEventHandler(handler: {
            self.queue.async {
                Task { onChange() }
            }
        })

        dispatchSource?.setCancelHandler(handler: { [weak self] in
            guard let self = self else { return }

            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.dispatchSource = nil
        })

        dispatchSource?.resume()
    }

    func terminate() {
        dispatchSource?.cancel()
    }

    deinit {
        Log.perf("FSNotifier for \(self.url) will be deinitialized.")
    }

}
