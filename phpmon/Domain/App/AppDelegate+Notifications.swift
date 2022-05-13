//
//  AppDelegate+Notifications.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import UserNotifications

extension AppDelegate {

    // MARK: - Notifications

    /**
     Sets up notifications. That does mean we need to ask for permission first.
     If we cannot get permission, we should log this.
     */
    public func setupNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert], completionHandler: { granted, error in
            if !granted {
                Log.warn("PHP Monitor does not have permission to show notifications.")
            }
            if let error = error {
                Log.err("PHP Monitor encounted an error determining notification permissions:")
                Log.err(error)
            }
        })
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
