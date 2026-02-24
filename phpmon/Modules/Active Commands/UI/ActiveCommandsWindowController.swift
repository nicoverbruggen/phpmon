//
//  ActiveCommandsWindowController.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class ActiveCommandsWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "ActiveCommands"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()

        let panel = NSPanel()
        panel.styleMask = [.titled, .closable, .miniaturizable, .resizable, .utilityWindow]
        panel.title = "Active Commands"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.delegate = delegate ?? windowController
        panel.contentView = NSHostingView(rootView: ActiveCommandsView())
        panel.setContentSize(NSSize(width: 500, height: 300))

        windowController.window = panel

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: ActiveCommandsWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(ActiveCommandsWC.self)
        WindowManager.withWindow(for: ActiveCommandsWC.self) { window in
            window.setCenterPosition(offsetY: 70)
        }
    }
}
