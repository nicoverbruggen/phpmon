//
//  LocalNotification.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import UserNotifications

class LocalNotification {
    
    public static func askForPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert], completionHandler: { granted, error in
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
    
    public static func send(title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: uuidString,
            content: content,
            trigger: nil
        )
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                print(error!)
            }
        }
    }
    
}
