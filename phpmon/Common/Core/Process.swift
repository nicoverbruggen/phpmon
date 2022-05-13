//
//  Process.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Process {

    /**
     When a process is running in the background, it can send content to standard
     output or standard error, just like it would in a terminal. Using `listen`
     allows us to react whenever data is received by running a particular closure,
     depending on which type of data is received.
     */
    public func listen(
        didReceiveStandardOutputData: @escaping (String) -> Void,
        didReceiveStandardErrorData: @escaping (String) -> Void
    ) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        self.standardOutput = outputPipe
        self.standardError = errorPipe

        [
         (outputPipe, didReceiveStandardOutputData),
         (errorPipe, didReceiveStandardErrorData)
        ].forEach { (pipe: Pipe, callback: @escaping (String) -> Void) in
            pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSFileHandleDataAvailable,
                object: pipe.fileHandleForReading,
                queue: nil
            ) { _ in
                if let outputString = String(
                    data: pipe.fileHandleForReading.availableData,
                    encoding: String.Encoding.utf8
                ) {
                    callback(outputString)
                }
                pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            }
        }
    }

    /**
     After the process is done running, you'll want to stop listening.
     */
    public func haltListening() {
        if let pipe = self.standardOutput as? Pipe {
            NotificationCenter.default.removeObserver(pipe.fileHandleForReading)
        }
        if let pipe = self.standardError as? Pipe {
            NotificationCenter.default.removeObserver(pipe.fileHandleForReading)
        }
    }

}
