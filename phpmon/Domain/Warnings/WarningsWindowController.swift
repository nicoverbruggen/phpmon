//
//  WarningsWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class WarningsWindowController: PMWindowController {

    // MARK: - Window Identifier

    override var windowName: String {
        return "Warnings"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: WarningListView())
        window.setContentSize(NSSize(width: 600, height: 480))

        App.shared.warningsWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.warningsWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.warningsWindowController?.showWindow(self)
        App.shared.warningsWindowController?.window?.setCenterPosition(offsetY: 70)

        NSApp.activate(ignoringOtherApps: true)
    }
}
