//
//  CommandHistoryWindowController.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class CommandHistoryWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "CommandHistory"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()

        let panel = NSPanel()
        panel.styleMask = [.titled, .closable, .miniaturizable, .resizable, .utilityWindow]
        panel.title = "command_history.title".localized
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.delegate = delegate ?? windowController
        panel.contentView = NSHostingView(rootView: CommandHistoryView(
            commandTracker: App.shared.container.commandTracker
        ))
        panel.setContentSize(NSSize(width: 600, height: 400))

        windowController.window = panel

        WindowManager.setController(windowController)
    }

    override func windowWillClose(_ notification: Notification) {
        super.windowWillClose(notification)

        // In the case of command history, we dismiss it
        WindowManager.unset(CommandHistoryWC.self)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: CommandHistoryWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(CommandHistoryWC.self)
        WindowManager.withWindow(for: CommandHistoryWC.self) { window in
            window.setCenterPosition(offsetY: 70)
        }
    }
}
