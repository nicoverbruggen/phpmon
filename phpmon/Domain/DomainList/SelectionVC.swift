//
//  SelectionVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class SelectionVC: NSViewController {
    
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
        // TODO
    }
    
    // MARK: - Outlet Interactions
    
    @IBAction func pressedCancel(_ sender: Any) {
        self.dismissView(outcome: .cancel)
    }
    
}
