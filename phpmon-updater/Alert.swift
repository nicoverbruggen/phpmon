//
//  Alert.swift
//  PHP Monitor Self-Updater
//
//  Created by Nico Verbruggen on 02/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class Alert {
    public static func show(description: String, shouldExit: Bool = true) async {
        await withUnsafeContinuation { continuation in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "The app could not be updated."
                alert.informativeText = description
                alert.addButton(withTitle: "OK")
                alert.alertStyle = .critical
                alert.runModal()
                if shouldExit {
                    exit(0)
                }
                continuation.resume()
            }
        }
    }
}
