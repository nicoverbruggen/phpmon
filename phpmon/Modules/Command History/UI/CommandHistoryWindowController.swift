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
        panel.title = "Command History"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.delegate = delegate ?? windowController
        panel.contentView = NSHostingView(rootView: CommandHistoryView(
            commandTracker: App.shared.container.commandTracker
        ))
        panel.setContentSize(NSSize(width: 500, height: 300))

        windowController.window = panel

        WindowManager.setController(windowController)
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
