//
//  DomainListWindowController.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 03/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import SwiftUI

class DomainListWindowController: PMWindowController, NSSearchFieldDelegate, NSToolbarDelegate {

    // MARK: - Window Identifier

    override var windowName: String {
        return "DomainList"
    }

    // MARK: - Toolbar

    private enum ToolbarIdentifiers {
        static let addLink = NSToolbarItem.Identifier("domainListAddLink")
        static let reload = NSToolbarItem.Identifier("domainListReload")
        static let search = NSToolbarItem.Identifier("domainListSearch")
    }

    let searchToolbarItem = NSSearchToolbarItem(itemIdentifier: ToolbarIdentifiers.search)

    /**
     Builds the window's toolbar (add link + reload + search), matching the
     configuration of the old storyboard's toolbar.
     */
    func configureToolbar() {
        let toolbar = NSToolbar(identifier: "domainListToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.showsBaselineSeparator = false

        searchToolbarItem.label = "Search"
        searchToolbarItem.visibilityPriority = NSToolbarItem.VisibilityPriority(rawValue: 1001)
        searchToolbarItem.searchField.placeholderString = "generic.search".localized
        searchToolbarItem.searchField.delegate = self

        window?.toolbar = toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ToolbarIdentifiers.addLink, ToolbarIdentifiers.reload, ToolbarIdentifiers.search]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case ToolbarIdentifiers.addLink:
            return makeToolbarButton(
                itemIdentifier, label: "Add Link", symbol: "plus", action: #selector(pressedAddLink(_:))
            )
        case ToolbarIdentifiers.reload:
            return makeToolbarButton(
                itemIdentifier, label: "Reload", symbol: "arrow.clockwise", action: #selector(pressedReload(_:))
            )
        case ToolbarIdentifiers.search:
            return searchToolbarItem
        default:
            return nil
        }
    }

    private func makeToolbarButton(
        _ identifier: NSToolbarItem.Identifier,
        label: String,
        symbol: String,
        action: Selector
    ) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.paletteLabel = label
        item.isBordered = true
        // The old storyboard used symbolScale="medium" for these icons.
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(scale: .medium))
        item.target = self
        item.action = action
        return item
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
            // Scheduled on the main run loop, so this fires on the main actor.
            MainActor.assumeIsolated {
                self.contentVC.searchedFor(text: searchField.stringValue)
            }
        })
    }

    // MARK: - Reload functionality

    @objc func pressedReload(_ sender: Any?) {
        Task { await contentVC.reloadDomains() }
    }

    @objc func pressedAddLink(_ sender: Any?) {
        showSelectionWindow()
    }

    // MARK: - Add a new site

    func showSelectionWindow() {
        var hostingController: NSHostingController<SelectDomainTypeView>!

        let view = SelectDomainTypeView(
            onCancel: {
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .cancel)
            },
            onCreateLink: {
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .continue)
                self.startCreateLinkFlow()
            },
            onCreateProxy: {
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .continue)
                self.startCreateProxyFlow()
            }
        )

        hostingController = NSHostingController(rootView: view)
        hostingController.sizingOptions = .preferredContentSize
        let sheetWindow = NSWindow(contentViewController: hostingController)
        sheetWindow.styleMask = [.titled, .fullSizeContentView]
        self.window?.beginSheet(sheetWindow)
    }

    func startCreateLinkFlow() {
        self.showFolderSelectionForLink()
    }

    func startCreateProxyFlow() {
        self.showProxyPopup()
    }

    // MARK: - Popups

    private func showFolderSelectionForLink() {
        let dialog = NSOpenPanel()
        dialog.message = "domain_list.add.modal_description".localized
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.beginSheetModal(for: self.window!) { response in
            let result = dialog.url
            if result != nil && response == .OK {
                let path: String = result!.path
                self.showLinkPopup(path)
            }
        }
    }

    private func showLinkPopup(_ folder: String) {
        var hostingController: NSHostingController<AddSiteView>!

        let view = AddSiteView(
            path: folder,
            tld: Valet.shared.config.tld,
            onCancel: {
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .cancel)
            },
            onConfirm: { name, secure in
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .OK)
                self.contentVC.setUIBusy()
                Task {
                    try? await ValetInteractor.shared.link(path: folder, domain: name)

                    await MainActor.run {
                        self.contentVC.setUINotBusy()
                        self.searchToolbarItem.searchField.stringValue = ""
                    }

                    await self.contentVC.addedNewSite(
                        name: name,
                        secureAfterLinking: secure
                    )
                }
            },
            domainExists: { name in
                Valet.shared.sites.contains(where: { $0.name == name })
            }
        )

        hostingController = NSHostingController(rootView: view)
        hostingController.sizingOptions = .preferredContentSize
        let sheetWindow = NSWindow(contentViewController: hostingController)
        sheetWindow.styleMask = [.titled, .fullSizeContentView]
        self.window?.beginSheet(sheetWindow)
    }

    private func showProxyPopup() {
        var hostingController: NSHostingController<AddProxyView>!

        let view = AddProxyView(
            tld: Valet.shared.config.tld,
            onCancel: {
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .cancel)
            },
            onConfirm: { domain, proxy, secure in
                guard let window = hostingController.view.window,
                      let parent = window.sheetParent else { return }
                parent.endSheet(window, returnCode: .OK)
                self.contentVC.setUIBusy()
                Task {
                    try? await ValetInteractor.shared.proxy(domain: domain, proxy: proxy, secure: secure)

                    await MainActor.run {
                        self.contentVC.setUINotBusy()
                        self.pressedReload(nil)
                    }
                }
            },
            domainExists: { name in
                Valet.shared.sites.contains(where: { $0.name == name })
            }
        )

        hostingController = NSHostingController(rootView: view)
        hostingController.sizingOptions = .preferredContentSize
        let sheetWindow = NSWindow(contentViewController: hostingController)
        sheetWindow.styleMask = [.titled, .fullSizeContentView]
        self.window?.beginSheet(sheetWindow)
    }
}
