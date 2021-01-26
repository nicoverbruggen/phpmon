//
//  Alert.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Alert {
    public static func present(
        messageText: String,
        informativeText: String,
        buttonTitle: String = "OK",
        secondButtonTitle: String = ""
    ) -> Bool {
        let alert = NSAlert.init()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        if (!secondButtonTitle.isEmpty) {
            alert.addButton(withTitle: secondButtonTitle)
        }
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public static func notify(message: String, info: String) {
        _ = self.present(messageText: message, informativeText: info, buttonTitle: "OK", secondButtonTitle: "")
    }
}
