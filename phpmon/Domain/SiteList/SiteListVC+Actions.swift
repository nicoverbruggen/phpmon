//
//  SiteListVC+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

extension SiteListVC {

    @objc func toggleSecure() {
        let rowToReload = tableView.selectedRow
        let originalSecureStatus = selectedSite!.secured
        let action = selectedSite!.secured ? "unsecure" : "secure"
        let selectedSite = selectedSite!
        let command = "cd '\(selectedSite.absolutePath)' && sudo \(Paths.valet) \(action) && exit;"
        
        waitAndExecute {
            Shell.run(command, requiresPath: true)
        } completion: { [self] in
            selectedSite.determineSecured()
            if selectedSite.secured == originalSecureStatus {
                BetterAlert()
                    .withInformation(
                        title: "site_list.alerts_status_not_changed.title".localized,
                        subtitle: "site_list.alerts_status_not_changed.desc".localized(command)
                    )
                    .withPrimary(text: "OK")
                    .show()
            } else {
                let newState = selectedSite.secured ? "secured" : "unsecured"
                LocalNotification.send(
                    title: "site_list.alerts_status_changed.title".localized,
                    subtitle: "site_list.alerts_status_changed.desc"
                        .localized(
                            "\(selectedSite.name).\(Valet.shared.config.tld)",
                            newState
                        )
                )
            }
            
            tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0, 1, 2, 3, 4])
            tableView.deselectRow(rowToReload)
            tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
        }
    }
    
    @objc func openInBrowser() {
        let prefix = selectedSite!.secured ? "https://" : "http://"
        let url = URL(string: "\(prefix)\(selectedSite!.name).\(Valet.shared.config.tld)")
        if url != nil {
            NSWorkspace.shared.open(url!)
        } else {
            BetterAlert()
                .withInformation(
                    title: "site_list.alert.invalid_folder_name".localized,
                    subtitle: "site_list.alert.invalid_folder_name_desc".localized
                )
                .withPrimary(text: "OK")
                .show()
        }
    }
    
    @objc func openInFinder() {
        Shell.run("open '\(selectedSite!.absolutePath)'")
    }
    
    @objc func openInTerminal() {
        Shell.run("open -b com.apple.terminal '\(selectedSite!.absolutePath)'")
    }
    
    @objc func openWithEditor(sender: EditorMenuItem) {
        guard let editor = sender.editor else { return }
        editor.openDirectory(file: selectedSite!.absolutePath)
    }
    
    @objc func isolateSite(sender: PhpMenuItem) {
        self.performAction(command: "cd '\(selectedSite!.absolutePath)' && sudo \(Paths.valet) isolate php@\(sender.version) && exit;") {
            self.selectedSite!.determineIsolated()
        }
    }
    
    @objc func removeIsolatedSite() {
        self.performAction(command: "cd '\(selectedSite!.absolutePath)' && sudo \(Paths.valet) unisolate && exit;") {
            self.selectedSite!.isolatedPhpVersion = nil
        }
    }
    
    @objc func unlinkSite() {
        guard let site = selectedSite else {
            return
        }
        
        if site.aliasPath == nil {
            return
        }
        
        Alert.confirm(
            onWindow: view.window!,
            messageText: "site_list.confirm_unlink".localized(site.name),
            informativeText: "site_link.confirm_link".localized,
            buttonTitle: "site_list.unlink".localized,
            secondButtonTitle: "Cancel",
            style: .critical,
            onFirstButtonPressed: {
                Shell.run("valet unlink '\(site.name)'", requiresPath: true)
                self.reloadSites()
            }
        )
    }
    
    private func performAction(command: String, beforeCellReload: @escaping () -> Void) {
        let rowToReload = tableView.selectedRow
        
        waitAndExecute {
            Shell.run(command, requiresPath: true)
        } completion: { [self] in
            beforeCellReload()
            tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0, 1, 2, 3, 4])
            tableView.deselectRow(rowToReload)
            tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
        }
    }
    
}
