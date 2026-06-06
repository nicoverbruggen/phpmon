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
