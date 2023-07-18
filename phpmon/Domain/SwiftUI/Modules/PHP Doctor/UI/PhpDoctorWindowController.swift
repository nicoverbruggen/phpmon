//
//  PhpDoctorWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/08/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class PhpDoctorWindowController: PMWindowController {

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
        window.contentView = NSHostingView(rootView: PhpDoctorView())
        window.setContentSize(NSSize(width: 600, height: 480))

        App.shared.phpDoctorWindowController = windowController
    }

    public static func show(delegate: NSWindowDelegate? = nil) {
        if App.shared.phpDoctorWindowController == nil {
            Self.create(delegate: delegate)
        }

        App.shared.phpDoctorWindowController?.showWindow(self)
        App.shared.phpDoctorWindowController?.window?.setCenterPosition(offsetY: 70)

        NSApp.activate(ignoringOtherApps: true)
    }
}
