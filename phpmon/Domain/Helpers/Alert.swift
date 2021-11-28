//
//  Alert.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Alert {
    
    public static func present(
        messageText: String,
        informativeText: String,
        buttonTitle: String = "OK",
        secondButtonTitle: String = "",
        style: NSAlert.Style = .informational
    ) -> Bool {
        let alert = NSAlert.init()
        alert.alertStyle = style
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        if (!secondButtonTitle.isEmpty) {
            alert.addButton(withTitle: secondButtonTitle)
        }
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public static func notify(message: String, info: String, style: NSAlert.Style = .informational) {
        _ = self.present(messageText: message, informativeText: info, buttonTitle: "OK", secondButtonTitle: "", style: style)
    }
    
}
