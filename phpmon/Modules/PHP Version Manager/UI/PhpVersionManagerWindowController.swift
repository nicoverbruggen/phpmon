//
//  PhpVersionManagerWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import SwiftUI

class PhpVersionManagerWindowController: PMWindowController {

    // MARK: - Window Identifier

    var view: PhpVersionManagerView!

    override var windowName: String {
        return "PhpVersionManager"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()
        windowController.view = PhpVersionManagerView(
            formulae: Brew.shared.formulae,
            handler: BrewPhpFormulaeHandler(App.shared.container)
        )

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: windowController.view)
        window.setContentSize(NSSize(width: 600, height: 800))

        WindowManager.setController(windowController)
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if !WindowManager.hasController(for: PhpVersionManagerWC.self) {
            Self.create(delegate: delegate)
        }

        WindowManager.show(PhpVersionManagerWC.self)
        WindowManager.controller(of: PhpVersionManagerWC.self)?
            .positionWindowInTopRightCorner()
    }
}
