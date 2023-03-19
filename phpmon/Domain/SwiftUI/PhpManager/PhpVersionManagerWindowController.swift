//
//  PhpVersionManagerWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa
import SwiftUI

class PhpVersionManagerWindowController: PMWindowController {

    // MARK: - Window Identifier

    var view: PhpFormulaeView!

    override var windowName: String {
        return "PhpFormulaeView"
    }

    public static func create(delegate: NSWindowDelegate?) {
        let windowController = Self()
        windowController.window = NSWindow()
        windowController.view = PhpFormulaeView(
            formulae: Brew.shared.formulae,
            handler: BrewFormulaeHandler()
        )

        guard let window = windowController.window else { return }
        window.title = ""
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.delegate = delegate ?? windowController
        window.contentView = NSHostingView(rootView: windowController.view)
        window.setContentSize(NSSize(width: 600, height: 480))

        App.shared.versionManagerWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.versionManagerWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.versionManagerWindowController?.showWindow(self)
        App.shared.versionManagerWindowController?.window?.setCenterPosition(offsetY: 70)

        NSApp.activate(ignoringOtherApps: true)
    }
}
