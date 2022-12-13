//
//  DomainListVC+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

extension DomainListVC {

    @objc func openInBrowser() {
        guard let selected = self.selected else {
            return
        }

        guard let url = selected.getListableUrl() else {
            BetterAlert()
                .withInformation(
                    title: "domain_list.alert.invalid_folder_name".localized,
                    subtitle: "domain_list.alert.invalid_folder_name_desc".localized
                )
                .withPrimary(text: "OK")
                .show()
            return
        }

        NSWorkspace.shared.open(url)
    }

    @objc func openInFinder() async {
        await Shell.quiet("open '\(selectedSite!.absolutePath)'")
    }

    @objc func openInTerminal() async {
        await Shell.quiet("open -b com.apple.terminal '\(selectedSite!.absolutePath)'")
    }

    @objc func openWithEditor(sender: EditorMenuItem) async {
        guard let editor = sender.editor else { return }
        await editor.openDirectory(file: selectedSite!.absolutePath)
    }

    // MARK: - UI interaction

    private func performAction(command: String, beforeCellReload: @escaping () -> Void) {
        let rowToReload = tableView.selectedRow

        waitAndExecute {
            await Shell.quiet(command)
        } completion: { [self] in
            beforeCellReload()
            tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0, 1, 2, 3, 4])
            tableView.deselectRow(rowToReload)
            tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
        }
    }

    private func reloadSelectedRow() {
        tableView.reloadData(forRowIndexes: [tableView.selectedRow], columnIndexes: [0, 1, 2, 3, 4])
        tableView.deselectRow(tableView.selectedRow)
        tableView.selectRowIndexes([tableView.selectedRow], byExtendingSelection: true)
    }

    // MARK: - Interactions with `valet` or terminal

    @objc func toggleSecure() {
        if selected is ValetSite {
            Task { toggleSecureForSite() }
        } else {
            Task { await toggleSecureForProxy() }
        }
    }

    func toggleSecureForProxy() async {
        guard let proxy = selectedProxy else { return }

        do {
            // Toggle secure
            try await proxy.toggleSecure()

            // Reload the UI
            self.reloadSelectedRow()

            // Send a notification about the new status (if applicable)
            LocalNotification.send(
                title: "domain_list.alerts_status_changed.title".localized,
                subtitle: "domain_list.alerts_status_changed.desc"
                    .localized(
                        "\(proxy.domain).\(Valet.shared.config.tld)",
                        proxy.secured
                    ),
                preference: .notifyAboutSecureToggle
            )
        } catch {
            let error = error as! ValetInteractionError

            BetterAlert()
                .withInformation(
                    title: "domain_list.alerts_status_not_changed.title".localized,
                    subtitle: "domain_list.alerts_status_not_changed.desc".localized(error.command)
                )
                .withPrimary(text: "OK")
                .show()
        }
    }

    func toggleSecureForSite() {
        let rowToReload = tableView.selectedRow
        let originalSecureStatus = selectedSite!.secured
        let action = selectedSite!.secured ? "unsecure" : "secure"
        let selectedSite = selectedSite!
        let command = "cd '\(selectedSite.absolutePath)' && sudo \(Paths.valet) \(action) && exit;"

        waitAndExecute {
            await Shell.quiet(command)
        } completion: { [self] in
            selectedSite.determineSecured()
            if selectedSite.secured == originalSecureStatus {
                BetterAlert()
                    .withInformation(
                        title: "domain_list.alerts_status_not_changed.title".localized,
                        subtitle: "domain_list.alerts_status_not_changed.desc".localized(command)
                    )
                    .withPrimary(text: "OK")
                    .show()
            } else {
                let newState = selectedSite.secured ? "secured" : "unsecured"
                LocalNotification.send(
                    title: "domain_list.alerts_status_changed.title".localized,
                    subtitle: "domain_list.alerts_status_changed.desc"
                        .localized(
                            "\(selectedSite.name).\(Valet.shared.config.tld)",
                            newState
                        ),
                    preference: .notifyAboutSecureToggle
                )
            }

            tableView.reloadData(forRowIndexes: [rowToReload], columnIndexes: [0, 1, 2, 3, 4])
            tableView.deselectRow(rowToReload)
            tableView.selectRowIndexes([rowToReload], byExtendingSelection: true)
        }
    }

    @objc func isolateSite(sender: PhpMenuItem) {
        let command = "sudo \(Paths.valet) isolate php@\(sender.version) --site '\(self.selectedSite!.name)' && exit;"

        self.performAction(command: command) {
            self.selectedSite!.determineIsolated()
            self.selectedSite!.determineComposerPhpVersion()

            if self.selectedSite!.isolatedPhpVersion == nil {
                BetterAlert()
                    .withInformation(
                        title: "domain_list.alerts_isolation_failed.title".localized,
                        subtitle: "domain_list.alerts_isolation_failed.subtitle".localized,
                        description: "domain_list.alerts_isolation_failed.desc".localized(command)
                    )
                    .withPrimary(text: "OK")
                    .show()
            }
        }
    }

    @objc func removeIsolatedSite() {
        self.performAction(command: "sudo \(Paths.valet) unisolate --site '\(self.selectedSite!.name)' && exit;") {
            self.selectedSite!.isolatedPhpVersion = nil
            self.selectedSite!.determineComposerPhpVersion()
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
            messageText: "domain_list.confirm_unlink".localized(site.name),
            informativeText: "domain_list.confirm_unlink_desc".localized,
            buttonTitle: "domain_list.unlink".localized,
            secondButtonTitle: "Cancel",
            style: .critical,
            onFirstButtonPressed: {
                self.waitAndExecute {
                    Task { await Shell.quiet("valet unlink '\(site.name)'") }
                } completion: {
                    Task { await self.reloadDomains() }
                }
            }
        )
    }

    @objc func removeProxy() {
        guard let proxy = selectedProxy else {
            return
        }

        Alert.confirm(
            onWindow: view.window!,
            messageText: "domain_list.confirm_unproxy".localized("\(proxy.domain).\(proxy.tld)"),
            informativeText: "domain_list.confirm_unproxy_desc".localized,
            buttonTitle: "domain_list.unproxy".localized,
            secondButtonTitle: "Cancel",
            style: .critical,
            onFirstButtonPressed: {
                self.waitAndExecute {
                    Task { await proxy.remove() }
                } completion: {
                    Task { await self.reloadDomains() }
                }
            }
        )
    }
}
