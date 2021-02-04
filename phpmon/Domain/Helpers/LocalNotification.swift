//
//  LocalNotification.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class LocalNotification {
    
    public static func send(title: String, subtitle: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        NSUserNotificationCenter.default.deliver(notification)
    }
    
}
