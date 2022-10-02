//
//  NoticeVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/02/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class BetterAlertVC: NSViewController {

    // MARK: - Outlets

    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelSubtitle: NSTextField!
    @IBOutlet weak var labelDescription: NSTextField!

    @IBOutlet weak var buttonPrimary: NSButton!
    @IBOutlet weak var buttonSecondary: NSButton!
    @IBOutlet weak var buttonTertiary: NSButton!

    var actionPrimary: (BetterAlertVC) -> Void = { _ in }
    var actionSecondary: ((BetterAlertVC) -> Void)?
    var actionTertiary: ((BetterAlertVC) -> Void)?

    @IBOutlet weak var imageView: NSImageView!

    @IBOutlet weak var primaryButtonTopMargin: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewWillAppear() {
        imageView.image = NSApp.applicationIconImage

        if actionSecondary == nil {
            buttonSecondary.isHidden = true
        }
        if actionTertiary == nil {
            buttonTertiary.isHidden = true
        }
    }

    override func viewDidAppear() {
        view.window?.makeFirstResponder(buttonPrimary)
    }

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

    // MARK: Outlet Actions

    @IBAction func primaryButtonAction(_ sender: Any) {
        self.actionPrimary(self)
    }

    @IBAction func secondaryButtonAction(_ sender: Any) {
        if self.actionSecondary != nil {
            self.actionSecondary!(self)
        } else {
            self.close(with: .alertSecondButtonReturn)
        }
    }

    @IBAction func tertiaryButtonAction(_ sender: Any) {
        if self.actionTertiary != nil {
            self.actionTertiary!(self)
        }
    }

    public func close(with code: NSApplication.ModalResponse) {
        self.view.window?.close()
        NSApplication.shared.stopModal(withCode: code)
    }

}
