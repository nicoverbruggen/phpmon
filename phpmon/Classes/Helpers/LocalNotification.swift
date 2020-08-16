//
//  LocalNotification.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/07/2020.
//  Copyright © 2020 Nico Verbruggen. All rights reserved.
//

import Foundation

class LocalNotification {
    public static func send(title: String, subtitle: String)
    {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        NSUserNotificationCenter.default.deliver(notification)
    }
}
