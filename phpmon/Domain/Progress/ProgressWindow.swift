//
//  ProgressView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class ProgressWindowController: NSWindowController, NSWindowDelegate {

    static func display(title: String, description: String) -> ProgressWindowController {
        let storyboard = NSStoryboard(name: "ProgressWindow", bundle: nil)

        let windowController = storyboard.instantiateController(
            withIdentifier: "progressWindow"
        ) as! ProgressWindowController

        windowController.showWindow(windowController)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.positionWindowInTopLeftCorner()

        windowController.progressView?.labelTitle.stringValue = title
        windowController.progressView?.labelDescription.stringValue = description

        NSApp.activate(ignoringOtherApps: true)

        return windowController
    }

    var progressView: ProgressViewController? {
        return self.contentViewController as? ProgressViewController
    }

    public func addToConsole(_ string: String) {
        guard let textView = self.progressView?.textView else {
            return
        }

        textView.string += string
        textView.scrollToEndOfDocument(nil)
    }

    public func setType(info: Bool = true) {
        guard let imageView = self.progressView?.imageViewType else {
            return
        }

        imageView.image = NSImage(named: info ? "NSInfo" : "NSCaution")
    }

    func windowWillClose(_ notification: Notification) {
        self.contentViewController = nil
    }

    deinit {
        Log.perf("Deinitializing ProgressWindowController")
    }

}

class ProgressViewController: NSViewController {

    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!

    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var imageViewType: NSImageView!

    deinit {
        Log.perf("Deinitializing ProgressViewController")
    }

}
