//
//  DomainListVC+ContextMenu.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension DomainListVC {
    internal func reloadContextMenu() {
        guard let selected = selected else {
            tableView.menu = nil
            AppMenu.actionsMenu?.title = "mm_actions".localized
            AppMenu.actionsMenu?.submenu = nil
            AppMenu.actionsMenu?.isEnabled = false
            return
        }

        if let selected = selected as? ValetSite {
            tableView.menu = addMenuItemsForSite(selected)
            AppMenu.actionsMenu?.title = "mm_actions".localized + " (\(selected.name).\(selected.tld))"
            AppMenu.actionsMenu?.submenu = tableView.menu
            AppMenu.actionsMenu?.isEnabled = true
            return
        }
        if let selected = selected as? ValetProxy {
            tableView.menu = addMenuItemsForProxy(selected)
            AppMenu.actionsMenu?.title = "mm_actions".localized + " (\(selected.domain).\(selected.tld))"
            AppMenu.actionsMenu?.submenu = tableView.menu
            AppMenu.actionsMenu?.isEnabled = true
            return
        }
    }

    // MARK: - Menu Items for Site

    private func addMenuItemsForSite(_ site: ValetSite) -> NSMenu? {
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

        addSeparator(to: menu)

        if let extensions = site.isolatedPhpVersion?.extensions ?? container.phpEnvs.phpInstall?.extensions,
           let version = site.isolatedPhpVersion?.versionNumber.short ?? container.phpEnvs.phpInstall?.version.short {
            menu.addItem(HeaderView.asMenuItem(text: "mi_detected_extensions".localized))
            addMenuItemsForExtensions(
                to: menu,
                for: extensions,
                version: version
            )
        }

        menu.addItem(HeaderView.asMenuItem(text: "domain_list.actions".localized))

        addToggleFavorite(to: menu, favorited: site.favorited)
        addToggleSecure(to: menu, secured: site.secured)
        addUnlink(to: menu, with: site)

        return menu
    }

    private func addSystemApps(to menu: NSMenu) {
        menu.addItem(HeaderView.asMenuItem(text: "domain_list.system_apps".localized))
        menu.addItem(NSMenuItem(
            title: "domain_list.open_in_finder".localized,
            action: #selector(self.openInFinder),
            keyEquivalent: "F",
            systemImage: "folder"
        ))
        menu.addItem(NSMenuItem(
            title: "domain_list.open_in_terminal".localized,
            action: #selector(self.openInTerminal),
            keyEquivalent: "T",
            systemImage: "apple.terminal.fill"
        ))
        menu.addItem(NSMenuItem(
            title: "domain_list.open_in_browser".localized,
            action: #selector(self.openInBrowser),
            keyEquivalent: "B",
            systemImage: "globe"
        ))
    }

    private func addDetectedApps(to menu: NSMenu) {
        if !applications.isEmpty {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(HeaderView.asMenuItem(text: "domain_list.detected_apps".localized))

            for editor in applications {
                let editorMenuItem = EditorMenuItem(
                    title: "domain_list.open_in".localized(editor.name),
                    action: #selector(self.openWithEditor(sender:)),
                    keyEquivalent: "",
                    systemImage: "arrow.up.right"
                )
                editorMenuItem.editor = editor
                menu.addItem(editorMenuItem)
            }
        }
    }

    private func addUnlink(to menu: NSMenu, with site: ValetSite) {
        if site.aliasPath != nil {
            menu.addItem(NSMenuItem(
                title: "domain_list.unlink".localized,
                action: #selector(self.unlinkSite),
                keyEquivalent: "",
                systemImage: "trash"
            ))
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

        for version in container.phpEnvs.availablePhpVersions.reversed() {
            let item = PhpMenuItem(
                title: "domain_list.always_use_php".localized(version),
                action: #selector(self.isolateSiteViaMenuItem),
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
                action: #selector(self.removeIsolatedSiteViaMenuItem)
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
        menu.addItem(NSMenuItem(
            title: secured
            ? "domain_list.unsecure".localized
            : "domain_list.secure".localized,
            action: #selector(toggleSecure),
            keyEquivalent: "",
            systemImage: secured ? "lock.slash" : "lock"
        ))
    }

    private func addToggleFavorite(to menu: NSMenu, favorited: Bool) {
        menu.addItem(NSMenuItem(
            title: favorited
            ? "domain_list.unfavorite".localized
            : "domain_list.favorite".localized,
            action: #selector(toggleFavorite),
            keyEquivalent: "",
            systemImage: favorited ? "star.slash.fill" : "star.fill"
        ))
    }

    private func addMenuItemsForExtensions(to menu: NSMenu, for extensions: [PhpExtension], version: String) {
        var items: [NSMenuItem] = [
            NSMenuItem(title: "domain_list.applies_to".localized(version))
        ]

        for phpExtension in extensions {
            let item = ExtensionMenuItem(
                title: "\(phpExtension.name) (\(phpExtension.fileNameOnly))",
                action: #selector(self.toggleExtension),
                keyEquivalent: ""
            )

            item.state = phpExtension.enabled ? .on : .off
            item.phpExtension = phpExtension

            items.append(item)
        }

        menu.addItem(NSMenuItem(title: "domain_list.extensions".localized, submenu: items))
        menu.addItem(NSMenuItem.separator())
    }

    // MARK: - Menu Items for Proxy

    private func addMenuItemsForProxy(_ proxy: ValetProxy) -> NSMenu {
        let menu = NSMenu()
        addOpenProxyInBrowser(to: menu)
        addSeparator(to: menu)
        addToggleFavorite(to: menu, favorited: proxy.favorited)
        addToggleSecure(to: menu, secured: proxy.secured)
        addRemoveProxy(to: menu)
        return menu
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
