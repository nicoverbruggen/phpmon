//
//  Alert.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

class Alert {

    public static func confirm(
        onWindow window: NSWindow,
        messageText: String,
        informativeText: String,
        buttonTitle: String = "generic.ok".localized,
        buttonIsDestructive: Bool = false,
        secondButtonTitle: String = "generic.cancel".localized,
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
        alert.buttons.first?.hasDestructiveAction = buttonIsDestructive
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
