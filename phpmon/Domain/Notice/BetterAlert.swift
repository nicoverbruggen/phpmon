//
//  Notice.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/02/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

@MainActor
class BetterAlert {

    var windowController: NSWindowController!

    var noticeVC: BetterAlertVC {
        return self.windowController.contentViewController as! BetterAlertVC
    }

    init() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        self.windowController = storyboard.instantiateController(
            withIdentifier: "noticeWindow"
        ) as? NSWindowController
    }

    public static func make() -> BetterAlert {
        return BetterAlert()
    }

    public func withPrimary(
        text: String,
        action: @MainActor @escaping (BetterAlertVC) -> Void = { vc in
            vc.close(with: .alertFirstButtonReturn)
        }
    ) -> Self {
        self.noticeVC.buttonPrimary.title = text
        self.noticeVC.actionPrimary = action
        return self
    }

    public func withSecondary(
        text: String,
        action: (@MainActor (BetterAlertVC) -> Void)? = { vc in
            vc.close(with: .alertSecondButtonReturn)
        }
    ) -> Self {
        self.noticeVC.buttonSecondary.title = text
        self.noticeVC.actionSecondary = action
        return self
    }

    public func withTertiary(
        text: String = "",
        action: (@MainActor (BetterAlertVC) -> Void)? = nil
    ) -> Self {
        if text == "" {
            self.noticeVC.buttonTertiary.bezelStyle = .helpButton
        }
        self.noticeVC.buttonTertiary.title = text
        self.noticeVC.actionTertiary = action
        return self
    }

    public func withInformation(
        title: String,
        subtitle: String,
        description: String = ""
    ) -> Self {
        self.noticeVC.labelTitle.stringValue = title
        self.noticeVC.labelSubtitle.stringValue = subtitle
        self.noticeVC.labelDescription.stringValue = description

        // If the description is missing, handle the excess space and change the top margin
        if description == "" {
            self.noticeVC.labelDescription.isHidden = true
            self.noticeVC.primaryButtonTopMargin.constant = 0
        }
        return self
    }

    /**
     Shows the modal and returns a ModalResponse.
     If you wish to simply show the alert and disregard the outcome, use `show`.
     */
    @MainActor public func runModal() -> NSApplication.ModalResponse {
        if !Thread.isMainThread {
            fatalError("You should always present alerts on the main thread!")
        }

        NSApp.activate(ignoringOtherApps: true)
        
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.setCenterPosition(offsetY: 70)
        return NSApplication.shared.runModal(for: windowController.window!)
    }

    /** Shows the modal and returns true if the user pressed the primary button. */
    @MainActor public func didSelectPrimary() -> Bool {
        return self.runModal() == .alertFirstButtonReturn
    }

    /**
     Shows the modal and does not return anything.
     */
    @MainActor public func show() {
        _ = self.runModal()
    }

    /**
     Shows the modal for a particular error.
     */
    @MainActor public static func show(for error: Error & AlertableError) {
        let key = error.getErrorMessageKey()
        return BetterAlert().withInformation(
            title: "\(key).title".localized,
            subtitle: "\(key).description".localized
        ).withPrimary(text: "generic.ok".localized).show()
    }
}
