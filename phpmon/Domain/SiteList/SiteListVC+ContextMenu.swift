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
        
        addIsolate(to: menu, with: site)
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
            keyEquivalent: "B"
        )
    }
    
    private func addDetectedApps(to menu: NSMenu) {
        if (applications.count > 0) {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "site_list.detected_apps".localized, action: nil, keyEquivalent: "")
            
            for (_, editor) in applications.enumerated() {
                let editorMenuItem = EditorMenuItem(
                    title: "Open with \(editor.name)",
                    action: #selector(self.openWithEditor(sender:)),
                    keyEquivalent: ""
                )
                editorMenuItem.editor = editor
                menu.addItem(editorMenuItem)
            }
        }
    }
    
    private func addUnlink(to menu: NSMenu, with site: ValetSite) {
        if (site.aliasPath != nil) {
            menu.addItem(
                withTitle: "site_list.unlink".localized,
                action: #selector(self.unlinkSite),
                keyEquivalent: ""
            )
            menu.addItem(NSMenuItem.separator())
        }
    }
    
    private func addIsolate(to menu: NSMenu, with site: ValetSite) {
        if site.isolatedPhpVersion == nil {
            // ISOLATION POSSIBLE
            let isolationMenuItem = NSMenuItem(title:"site_list.isolate".localized, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            submenu.addItem(withTitle: "Choose a PHP version", action: nil, keyEquivalent: "")
            for version in PhpEnv.shared.availablePhpVersions.reversed() {
                let item = PhpMenuItem(title: "Always use PHP \(version)", action: #selector(self.isolateSite), keyEquivalent: "")
                item.version = version
                submenu.addItem(item)
            }
            menu.setSubmenu(submenu, for: isolationMenuItem)
            
            menu.addItem(isolationMenuItem)
            menu.addItem(NSMenuItem.separator())
        } else {
            // REMOVE ISOLATION POSSIBLE
            menu.addItem(
                withTitle: "site_list.remove_isolation".localized,
                action: #selector(self.removeIsolatedSite),
                keyEquivalent: ""
            )
            menu.addItem(NSMenuItem.separator())
        }
    }
    
    private func addToggleSecure(to menu: NSMenu, with site: ValetSite) {
        menu.addItem(
            withTitle: site.secured
            ? "site_list.unsecure".localized
            : "site_list.secure".localized,
            action: #selector(toggleSecure),
            keyEquivalent: ""
        )
    }
    
    private func addSeparator(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
    }
    
}
