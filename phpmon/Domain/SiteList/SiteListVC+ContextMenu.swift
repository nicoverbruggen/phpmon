//
//  SiteListVC+ContextMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension SiteListVC {
    
    internal func reloadContextMenu() {
        guard let site = selectedSite else {
            tableView.menu = nil
            return
        }
        
        let menu = NSMenu()
        
        addSystemApps(to: menu)
        addSeparator(to: menu)
        addDetectedApps(to: menu)
        addSeparator(to: menu)
        
        addUnlink(to: menu, with: site)
        addToggleSecure(to: menu, with: site)
        
        tableView.menu = menu
    }
    
    private func addSystemApps(to menu: NSMenu) {
        menu.addItem(withTitle: "site_list.system_apps".localized, action: nil, keyEquivalent: "")
        menu.addItem(
            withTitle: "site_list.open_in_finder".localized,
            action: #selector(self.openInFinder),
            keyEquivalent: "F"
        )
        menu.addItem(
            withTitle: "site_list.open_in_terminal".localized,
            action: #selector(self.openInTerminal),
            keyEquivalent: "T"
        )
        menu.addItem(
            withTitle: "site_list.open_in_browser".localized,
            action: #selector(self.openInBrowser),
            keyEquivalent: "O"
        )
    }
    
    private func addDetectedApps(to menu: NSMenu) {
        if (applications.count > 0) {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "site_list.detected_apps".localized, action: nil, keyEquivalent: "")
            
            for (index, editor) in applications.enumerated() {
                let editorMenuItem = EditorMenuItem(
                    title: "Open with \(editor.name)",
                    action: #selector(self.openWithEditor(sender:)),
                    keyEquivalent: "\(index + 1)"
                )
                editorMenuItem.editor = editor
                menu.addItem(editorMenuItem)
            }
        }
    }
    
    private func addUnlink(to menu: NSMenu, with site: Valet.Site) {
        if (site.aliasPath != nil) {
            menu.addItem(
                withTitle: "site_list.unlink".localized,
                action: #selector(self.unlinkSite),
                keyEquivalent: "U"
            )
            menu.addItem(NSMenuItem.separator())
        }
    }
    
    private func addToggleSecure(to menu: NSMenu, with site: Valet.Site) {
        menu.addItem(
            withTitle: site.secured
            ? "site_list.unsecure".localized
            : "site_list.secure".localized,
            action: #selector(toggleSecure),
            keyEquivalent: "L"
        )
    }
    
    private func addSeparator(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
    }
    
}
