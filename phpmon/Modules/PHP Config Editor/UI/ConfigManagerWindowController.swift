//
//  ConfigManagerWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/09/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class PhpConfigManagerWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "ConfigManager"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: ConfigManagerView())
        window.setContentSize(NSSize(width: 600, height: 480))

        App.shared.phpConfigManagerWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.phpConfigManagerWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.phpConfigManagerWindowController?.showWindow(self)
        App.shared.phpConfigManagerWindowController?.positionWindowInTopRightCorner()

        NSApp.activate(ignoringOtherApps: true)
        App.shared.phpConfigManagerWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}
