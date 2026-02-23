//
//  PhpExtensionManagerWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/11/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import SwiftUI

class PhpExtensionManagerWindowController: PMWindowController {

    // MARK: - Window Identifier

    var view: PhpExtensionManagerView!

    override var windowName: String {
        return "PhpExtensionManager"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()

        windowController.window = NSWindow()
        windowController.view = PhpExtensionManagerView()

        guard let window = windowController.window else { return }
        window.title = "phpextman.window.title".localized
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.titlebarAppearsTransparent = false
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: windowController.view)
        window.setContentSize(NSSize(width: 600, height: 800))

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: PhpExtensionManagerWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(PhpExtensionManagerWC.self)
        WindowManager.controller(of: PhpExtensionManagerWC.self)?
            .positionWindowInTopRightCorner()
    }
}
