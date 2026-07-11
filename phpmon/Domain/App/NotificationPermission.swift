//
//  NotificationPermission.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation
import UserNotifications

struct NotificationPermission {
    static func request() {
        // Never request permission with a testable (fake) container active:
        // on a machine without a stored decision (e.g. a fresh CI runner),
        // this presents a system permission prompt on top of the app, which
        // blocks the UI tests' assertions. (Since the fake configuration seeds
        // a launch count, the request would otherwise fire on every launch.)
        if App.shared.container.filesystem is TestableFileSystem {
            return
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: [.alert]) { granted, error in
            if !granted {
                Log.warn("PHP Monitor does not have permission to show notifications.")
            }
            if let error = error {
                Log.err("PHP Monitor encounted an error determining notification permissions:")
                Log.err(error)
            }
        }
    }
}
