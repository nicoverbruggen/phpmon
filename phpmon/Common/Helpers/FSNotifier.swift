//
//  FSNotifier.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/01/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

class FSNotifier {
    enum Kind {
        case homebrewLocks, homebrewBinaries
    }

    public static var shared: FSNotifier! = nil

    let queue = DispatchQueue(label: "FSWatch2Queue", attributes: .concurrent)

    var lastUpdate: TimeInterval?
    var linked: Bool

    private var fileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    internal let url: URL

    init(for url: URL, eventMask: DispatchSource.FileSystemEvent, onChange: @escaping () -> Void) {
        self.url = url

        self.linked = FileSystem.fileExists(Paths.php)
        print("Initial PHP linked state: \(linked)")

        fileDescriptor = open(url.path, O_EVTONLY)

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: eventMask,
            queue: self.queue
        )

        dispatchSource?.setEventHandler(handler: {
            let distance = self.lastUpdate?.distance(to: Date().timeIntervalSince1970)

            if distance == nil || distance != nil && distance! > 1.00 {
                print("FS event fired, checking in 1s, no duplicate FS events will be acted upon")

                self.lastUpdate = Date().timeIntervalSince1970

                Task {
                    await delay(seconds: 1)

                    let newLinked = FileSystem.fileExists(Paths.php)

                    if newLinked != self.linked {
                        self.linked = newLinked

                        Log.info("The status of the PHP binary has changed!")

                        if newLinked {
                            Log.info("php is linked")
                        } else {
                            Log.info("php is not linked")
                        }
                    }

                    onChange()
                }
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
