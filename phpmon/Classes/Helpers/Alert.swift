//
//  Alert.swift
//  phpmon
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Alert {
    public static func present(
        messageText: String,
        informativeText: String,
        buttonTitle: String = "OK"
    ) {
        let alert = NSAlert.init()
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        alert.runModal()
    }
}
