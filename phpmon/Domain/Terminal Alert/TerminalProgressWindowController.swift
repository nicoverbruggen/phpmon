//
//  TerminalProgressWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI

class TerminalProgressWindowController: NSWindowController, NSWindowDelegate {

    /// The state rendered by the hosted `ProgressPanelView`.
    let model = ProgressPanelModel()

    static func display(title: String, description: String) -> TerminalProgressWindowController {
        let windowController = TerminalProgressWindowController()

        // The panel configuration matches the old `ProgressWindow.storyboard`:
        // a utility panel with a transparent, title-less titlebar.
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 591, height: 270),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.animationBehavior = .none
        panel.isReleasedWhenClosed = false
        panel.delegate = windowController

        windowController.model.title = title
        windowController.model.descriptionText = description
        panel.contentView = NSHostingView(rootView: ProgressPanelView(model: windowController.model))

        windowController.window = panel

        windowController.showWindow(windowController)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.positionWindowInTopRightCorner()

        NSApp.activate(ignoringOtherApps: true)

        return windowController
    }

    public func addToConsole(_ string: String) {
        Task { @MainActor in
            self.model.consoleText += string
        }
    }

    public func setType(info: Bool = true) {
        model.isInfo = info
    }

    public func setTitle(_ title: String) {
        model.title = title
    }

    public func setDescription(_ description: String) {
        model.descriptionText = description
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

}
