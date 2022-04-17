//
//  AddSiteVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class AddProxyVC: NSViewController, NSTextFieldDelegate {
    
    // MARK: - Outlets
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStaticLocalisedStrings()
    }
    
    private func dismissView(outcome: NSApplication.ModalResponse) {
        guard let window = self.view.window, let parent = window.sheetParent else { return }
        parent.endSheet(window, returnCode: outcome)
    }
    
    // MARK: - Localisation
    
    func loadStaticLocalisedStrings() {

    }
    
    // MARK: - Outlet Interactions
    
    @IBAction func pressedCreateProxy(_ sender: Any) {
        // valet proxy (domain) http://127.0.0.1:90 (--secure)
    }
    
    @IBAction func pressedCancel(_ sender: Any) {
        self.dismissView(outcome: .cancel)
    }
    
}
