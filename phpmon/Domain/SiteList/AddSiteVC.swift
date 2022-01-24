//
//  AddSiteVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class AddSiteVC: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var linkName: NSTextField!
    @IBOutlet weak var previewText: NSTextField!
    @IBOutlet weak var buttonSecure: NSButton!
    
    @IBOutlet weak var buttonCreateLink: NSButton!
    
    @IBAction func pressedCreateLink(_ sender: Any) {
        let path = self.pathControl.url!.path
        let name = self.linkName.stringValue
        
        // TODO: Check if the path still exists
        Shell.run("cd '\(path)' && \(Paths.valet) link '\(name)'", requiresPath: true)
        self.view.window!.close()
        
        // Reset search
        App.shared.siteListWindowController?
            .searchToolbarItem
            .searchField.stringValue = ""
        
        // Add the new item and scrolls to it
        App.shared.siteListWindowController?
            .contentVC
            .addedNewSite(
                name: name,
                secure: buttonSecure.state == .on
            )
    }
    
    @IBAction func pressedCancel(_ sender: Any) {
        self.view.window!.close()
    }
    
    @IBAction func pressedSecure(_ sender: Any) {
        updatePreview()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateTextField()
    }
    
    func updateTextField() {
        self.linkName.stringValue = self.linkName.stringValue
            .replacingOccurrences(of: " ", with: "-")
        
        buttonCreateLink.isEnabled = !self.linkName.stringValue.isEmpty
        self.updatePreview()
    }
    
    func updatePreview() {
        previewText.stringValue = "site_list.add.folder_available"
            .localized(
                self.buttonSecure.state == .on ? "https" : "http",
                self.linkName.stringValue,
                Valet.shared.config.tld
            )
    }
}
