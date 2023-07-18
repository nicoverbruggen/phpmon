//
//  SelectionVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class SelectionVC: NSViewController {

    weak var domainListWC: DomainListWindowController?

    @IBOutlet weak var textFieldTitle: NSTextField!
    @IBOutlet weak var textFieldDescription: NSTextField!
    @IBOutlet weak var buttonCreateLink: NSButton!
    @IBOutlet weak var buttonCreateProxy: NSButton!
    @IBOutlet weak var buttonCancel: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadStaticLocalisedStrings()
    }

    override func viewDidAppear() {
        view.window?.makeFirstResponder(buttonCreateLink)
    }

    private func dismissView(outcome: NSApplication.ModalResponse) {
        guard let window = self.view.window, let parent = window.sheetParent else { return }
        parent.endSheet(window, returnCode: outcome)
    }

    // MARK: - Localisation

    func loadStaticLocalisedStrings() {
        textFieldTitle.stringValue = "selection.title".localized
        textFieldDescription.stringValue = "selection.description".localized
        buttonCancel.title = "selection.cancel".localized
        buttonCreateLink.title = "selection.create_link".localized
        buttonCreateProxy.title = "selection.create_proxy".localized
    }

    // MARK: - Outlet Interactions

    @IBAction func pressedCreateLink(_ sender: Any) {
        self.dismissView(outcome: .continue)
        domainListWC?.startCreateLinkFlow()
    }

    @IBAction func pressedCreateProxy(_ sender: Any) {
        self.dismissView(outcome: .continue)
        domainListWC?.startCreateProxyFlow()
    }

    @IBAction func pressedCancel(_ sender: Any) {
        self.dismissView(outcome: .cancel)
    }

}
