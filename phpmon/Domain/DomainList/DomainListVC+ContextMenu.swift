//
//  DomainListVC+ContextMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {

    internal func reloadContextMenu() {
        guard let selected = selected else {
            tableView.menu = nil
            return
        }

        if let selected = selected as? ValetSite {
            addMenuItemsForSite(selected)
            return
        }
        if let selected = selected as? ValetProxy {
            addMenuItemsForProxy(selected)
            return
        }
    }

    // MARK: - Menu Items for Site

    private func addMenuItemsForSite(_ site: ValetSite) {
        let menu = NSMenu()

        addSystemApps(to: menu)
        addSeparator(to: menu)
        addDetectedApps(to: menu)
        addSeparator(to: menu)

        if Valet.enabled(feature: .isolatedSites) {
            addIsolate(to: menu, with: site)
        } else {
            addDisabledIsolation(to: menu)
        }

        addUnlink(to: menu, with: site)
        addToggleSecure(to: menu, secured: site.secured)

        tableView.menu = menu
    }

    private func addSystemApps(to menu: NSMenu) {
        menu.addItem(withTitle: "domain_list.system_apps".localized, action: nil, keyEquivalent: "")
        menu.addItem(
            withTitle: "domain_list.open_in_finder".localized,
            action: #selector(self.openInFinder),
            keyEquivalent: "F"
        )
        menu.addItem(
            withTitle: "domain_list.open_in_terminal".localized,
            action: #selector(self.openInTerminal),
            keyEquivalent: "T"
        )
        menu.addItem(
            withTitle: "domain_list.open_in_browser".localized,
            action: #selector(self.openInBrowser),
            keyEquivalent: "B"
        )
    }

    private func addDetectedApps(to menu: NSMenu) {
        if !applications.isEmpty {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "domain_list.detected_apps".localized, action: nil, keyEquivalent: "")

            for editor in applications {
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
        if site.aliasPath != nil {
            menu.addItem(
                withTitle: "domain_list.unlink".localized,
                action: #selector(self.unlinkSite),
                keyEquivalent: ""
            )
            menu.addItem(NSMenuItem.separator())
        }
    }

    private func addDisabledIsolation(to menu: NSMenu) {
        menu.addItem(withTitle: "domain_list.isolation_unavailable".localized, action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
    }

    private func addIsolate(to menu: NSMenu, with site: ValetSite) {
        if site.isolatedPhpVersion == nil {
            // ISOLATION POSSIBLE
            let isolationMenuItem = NSMenuItem(title: "domain_list.isolate".localized, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            submenu.addItem(withTitle: "Choose a PHP version", action: nil, keyEquivalent: "")
            for version in PhpEnv.shared.availablePhpVersions.reversed() {
                let item = PhpMenuItem(
                    title: "Always use PHP \(version)",
                    action: #selector(self.isolateSite),
                    keyEquivalent: ""
                )
                item.version = version
                submenu.addItem(item)
            }
            menu.setSubmenu(submenu, for: isolationMenuItem)

            menu.addItem(isolationMenuItem)
            menu.addItem(NSMenuItem.separator())
        } else {
            // REMOVE ISOLATION POSSIBLE
            menu.addItem(
                withTitle: "domain_list.remove_isolation".localized,
                action: #selector(self.removeIsolatedSite),
                keyEquivalent: ""
            )
            menu.addItem(NSMenuItem.separator())
        }
    }

    private func addToggleSecure(to menu: NSMenu, secured: Bool) {
        menu.addItem(
            withTitle: secured
            ? "domain_list.unsecure".localized
            : "domain_list.secure".localized,
            action: #selector(toggleSecure),
            keyEquivalent: ""
        )
    }

    // MARK: - Menu Items for Proxy

    private func addMenuItemsForProxy(_ proxy: ValetProxy) {
        let menu = NSMenu()
        addOpenProxyInBrowser(to: menu)
        addSeparator(to: menu)
        addToggleSecure(to: menu, secured: proxy.secured)
        addRemoveProxy(to: menu)
        tableView.menu = menu
    }

    private func addOpenProxyInBrowser(to menu: NSMenu) {
        menu.addItem(
            withTitle: "domain_list.open_in_browser".localized,
            action: #selector(self.openInBrowser),
            keyEquivalent: "B"
        )
    }

    private func addRemoveProxy(to menu: NSMenu) {
        menu.addItem(
            withTitle: "domain_list.unproxy".localized,
            action: #selector(self.removeProxy),
            keyEquivalent: ""
        )
    }

    // MARK: - Shared

    private func addSeparator(to menu: NSMenu) {
        menu.addItem(NSMenuItem.separator())
    }

}
