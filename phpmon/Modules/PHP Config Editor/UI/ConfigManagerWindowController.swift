//
//  ConfigManagerWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/09/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: PhpConfigManagerWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(PhpConfigManagerWC.self)
        WindowManager.controller(of: PhpConfigManagerWC.self)?
            .positionWindowInTopRightCorner()
    }
}
