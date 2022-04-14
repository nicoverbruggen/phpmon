//
//  DomainListWC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

class DomainListWC: PMWindowController, NSSearchFieldDelegate, NSToolbarDelegate {
    
    // MARK: - Window Identifier
    
    override var windowName: String {
        return "DomainList"
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var searchToolbarItem: NSSearchToolbarItem!
    
    // MARK: - Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.searchToolbarItem.searchField.delegate = self
        self.searchToolbarItem.searchField.becomeFirstResponder()
    }
    
    // MARK: - Search functionality
    
    var contentVC: DomainListVC {
        return self.contentViewController as! DomainListVC
    }
    
    var searchTimer: Timer?
    
    func controlTextDidChange(_ notification: Notification) {
        guard let searchField = notification.object as? NSSearchField else {
            return
        }
        
        self.searchTimer?.invalidate()
        
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false, block: { _ in
            self.contentVC.searchedFor(text: searchField.stringValue)
        })
    }
    
    // MARK: - Reload functionality
    
    @IBAction func pressedReload(_ sender: Any?) {
        contentVC.reloadSites()
    }
    
    @IBAction func pressedAddLink(_ sender: Any?) {
        showSelectionWindow()
    }
    
    // MARK: - Add a new site
    
    func showSelectionWindow() {
        let storyboard = NSStoryboard(name: "Main", bundle : nil)
        
        let windowController = storyboard.instantiateController(
            withIdentifier: "showSelectionWindow"
        ) as! NSWindowController
        
        // let viewController = windowController.window!.contentViewController!
        
        self.window?.beginSheet(windowController.window!)
    }
    
    func selectFolder() {
        let dialog = NSOpenPanel()
        dialog.message = "domain_list.add.modal_description".localized
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.beginSheetModal(for: self.window!) { response in
            let result = dialog.url
            if (result != nil && response == .OK) {
                let path: String = result!.path
                self.showSitePopup(path)
            }
        }
    }
    
    func showSitePopup(_ folder: String) {
        let storyboard = NSStoryboard(name: "Main", bundle : nil)
        
        let windowController = storyboard.instantiateController(
            withIdentifier: "addSiteWindow"
        ) as! NSWindowController
        
        let viewController = windowController.window!.contentViewController as! AddSiteVC
        viewController.pathControl.url = URL(fileURLWithPath: folder)
        viewController.linkName.stringValue = String(folder.split(separator: "/").last!)
        viewController.updateTextField()
        
        self.window?.beginSheet(windowController.window!)
    }
}
