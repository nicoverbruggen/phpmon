//
//  AppDelegate+Notifications.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import UserNotifications

extension AppDelegate {

    // MARK: - Notifications

    /**
     Sets up notifications by ensuring the app delegate receives notification callbacks.
     */
    public func setupNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
    }

    /**
     Ensure that the application displays notifications even when the app is active.
     */
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }

}
