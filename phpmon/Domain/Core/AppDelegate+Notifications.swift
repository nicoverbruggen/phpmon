//
//  AppDelegate+Notifications.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 06/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import UserNotifications

extension AppDelegate {
    
    // MARK: - Notifications
    
    public func setupNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert], completionHandler: { granted, error in
            if granted {
                print("PHP Monitor has permission to show notifications.")
            } else {
                print("PHP Monitor does not have permission to show notifications.")
            }
            if let error = error {
                print("PHP Monitor encounted an error determining notification permissions:")
                print(error)
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
