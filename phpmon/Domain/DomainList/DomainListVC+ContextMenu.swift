//
//  DomainListVC+ContextMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
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

        menu.addItem(HeaderView.asMenuItem(text: "domain_list.actions".localized))
        addToggleSecure(to: menu, secured: site.secured)
        addUnlink(to: menu, with: site)

        tableView.menu = menu
    }

    private func addSystemApps(to menu: NSMenu) {
        menu.addItem(HeaderView.asMenuItem(text: "domain_list.system_apps".localized))
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
            menu.addItem(HeaderView.asMenuItem(text: "domain_list.detected_apps".localized))

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
        menu.addItem(HeaderView.asMenuItem(text: "domain_list.site_isolation".localized))
        menu.addItem(withTitle: "domain_list.isolation_unavailable".localized, action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
    }

    private func addIsolate(to menu: NSMenu, with site: ValetSite) {
        var items: [NSMenuItem] = []

        for version in PhpEnv.shared.availablePhpVersions.reversed() {
            let item = PhpMenuItem(
                title: "domain_list.always_use_php".localized(version),
                action: #selector(self.isolateSite),
                keyEquivalent: ""
            )
            if site.servingPhpVersion == version && site.isolatedPhpVersion != nil {
                item.state = .on
                item.action = nil
            }
            item.version = version
            items.append(item)
        }

        // Add the option to remove site isolation
        if site.isolatedPhpVersion != nil {
            items.append(NSMenuItem.separator())
            items.append(NSMenuItem(
                title: "domain_list.remove_isolation".localized,
                action: #selector(self.removeIsolatedSite)
            ))
        }

        menu.addItem(HeaderView.asMenuItem(text: "domain_list.site_isolation".localized))
        menu.addItem(NSMenuItem(title: "domain_list.isolate".localized, submenu: items))

        if site.isolatedPhpVersion != nil {
            menu.addItem(NSMenuItem(
                title: "domain_list.use_in_terminal".localized(site.isolatedPhpVersion!.versionNumber.text),
                action: #selector(self.useInTerminal)
            ))
        }
        menu.addItem(NSMenuItem.separator())
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
