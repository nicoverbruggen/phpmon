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

    @IBOutlet weak var textFieldTitle: NSTextField!
    @IBOutlet weak var textFieldSecure: NSTextField!
    @IBOutlet weak var textFieldError: NSTextField!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStaticLocalisedStrings()
    }
    
    // MARK: - Localisation
    
    func loadStaticLocalisedStrings() {
        textFieldTitle.stringValue = "site_list.add.link_folder".localized
        linkName.placeholderString = "site_list.add.domain_name_placeholder".localized
        textFieldSecure.stringValue = "site_list.add.secure_description".localized
    }
    
    // MARK: - Outlet Interactions
    
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
    
    // MARK: - Text Field Delegate
    
    func controlTextDidChange(_ obj: Notification) {
        updateTextField()
    }
    
    // MARK: - Helper Methods
    
    private func isValidLinkName(_ name: String) -> Bool {
        if self.linkName.stringValue.isEmpty {
            self.textFieldError.isHidden = false
            self.textFieldError.stringValue = "site_list.add.errors.empty".localized
            return false
        }
        
        if Valet.shared.sites.contains(where: { $0.name == name }) {
            self.textFieldError.isHidden = false
            self.textFieldError.stringValue = "site_list.add.errors.already_exists".localized
            return false
        }
        
        self.textFieldError.isHidden = true
        return true
    }
    
    func updateTextField() {
        self.linkName.stringValue = self.linkName.stringValue
            .replacingOccurrences(of: " ", with: "-")
        
        buttonCreateLink.isEnabled = isValidLinkName(self.linkName.stringValue)
        self.updatePreview()
    }
    
    func updatePreview() {
        buttonSecure.title = "site_list.add.secure_after_creation"
            .localized(
                self.linkName.stringValue,
                Valet.shared.config.tld
            )
        
        previewText.stringValue = "site_list.add.folder_available"
            .localized(
                self.buttonSecure.state == .on ? "https" : "http",
                self.linkName.stringValue,
                Valet.shared.config.tld
            )
    }
}
