//
//  LaunchControl.swift
//  PHP Monitor Self-Updater
//
//  Created by Nico Verbruggen on 02/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class LaunchControl {
    public static func smartRestart(priority: [String]) async {
        for appPath in priority {
            if FileManager.default.fileExists(atPath: appPath) {
                let app = await LaunchControl.startApplication(at: appPath)
                if app != nil {
                    return
                }
            }
        }
    }

    public static func terminateApplications(bundleIds: [String]) async {
        let runningApplications = NSWorkspace.shared.runningApplications

        // Terminate all instances found
        for id in bundleIds {
            if let phpmon = runningApplications.first(where: {
                (application) in return application.bundleIdentifier == id
            }) {
                phpmon.terminate()
            }
        }
    }

    public static func startApplication(at path: String) async -> NSRunningApplication? {
        await withCheckedContinuation { continuation in
            let url = NSURL(fileURLWithPath: path, isDirectory: true) as URL
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { phpmon, error in
                continuation.resume(returning: phpmon)
            }
        }
    }
}
