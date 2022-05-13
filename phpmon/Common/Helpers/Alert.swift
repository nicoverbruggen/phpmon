//
//  Alert.swift
//  PHP Monitor
//
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Alert {

    public static func confirm(
        onWindow window: NSWindow,
        messageText: String,
        informativeText: String,
        buttonTitle: String = "OK",
        secondButtonTitle: String = "Cancel",
        style: NSAlert.Style = .warning,
        onFirstButtonPressed: @escaping (() -> Void)
    ) {
        if !Thread.isMainThread {
            fatalError("You should always present alerts on the main thread!")
        }

        let alert = NSAlert.init()
        alert.alertStyle = style
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonTitle)
        if !secondButtonTitle.isEmpty {
            alert.addButton(withTitle: secondButtonTitle)
        }
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                onFirstButtonPressed()
            }
        }
    }

}
