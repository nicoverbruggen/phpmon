//
//  DomainListVC+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/12/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
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
                .withPrimary(text: "generic.ok".localized)
                .show()
            return
        }

        NSWorkspace.shared.open(url)
    }

    @objc func openInFinder() {
        Task { return await Shell.quiet("open '\(selectedSite!.absolutePath)'") }
    }

    @objc func openInTerminal() {
        Task { await Shell.quiet("open -b com.apple.terminal '\(selectedSite!.absolutePath)'") }
    }

    @objc func openWithEditor(sender: EditorMenuItem) {
        guard let editor = sender.editor else { return }
        editor.openDirectory(file: selectedSite!.absolutePath)
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
            Task { await toggleSecure(site: selected as! ValetSite) }
        }

        if selected is ValetProxy {
            Task { await toggleSecure(proxy: selected as! ValetProxy) }
        }
    }

    func toggleSecure(proxy: ValetProxy) async {
        waitAndExecute {
            do {
                // Recreate proxy as secure or unsecured proxy
                try await proxy.toggleSecure()
                // Send a notification about the new status (if applicable)
                self.notifyAboutModifiedSecureStatus(domain: proxy.domain, secured: proxy.secured)
                // Reload the UI (do this last so we don't invalidate the proxy)
                self.reloadSelectedRow()
            } catch {
                // Notify the user about a failed command
                let error = error as! ValetInteractionError
                self.notifyAboutFailedSecureStatus(command: error.command)
            }
        }
    }

    func toggleSecure(site: ValetSite) async {
        waitAndExecute {
            do {
                // Instruct Valet to secure or unsecure a site
                try await site.toggleSecure()
                // Send a notification about the new status (if applicable)
                self.notifyAboutModifiedSecureStatus(domain: site.name, secured: site.secured)
                // Reload the UI (do this last so we don't invalidate the site)
                self.reloadSelectedRow()
            } catch {
                // Notify the user about a failed command
                let error = error as! ValetInteractionError
                self.notifyAboutFailedSecureStatus(command: error.command)
            }
        }
    }

    @objc func isolateSite(sender: PhpMenuItem) {
        guard let site = selectedSite else {
            return
        }

        waitAndExecute {
            do {
                // Instruct Valet to isolate a given PHP version
                try await site.isolate(version: sender.version)
                // Reload the UI
                self.reloadSelectedRow()
            } catch {
                // Notify the user about a failed command
                let error = error as! ValetInteractionError
                self.notifyAboutFailedSiteIsolation(command: error.command)
            }
        }
    }

    @objc func removeIsolatedSite() {
        guard let site = selectedSite else {
            return
        }

        waitAndExecute {
            do {
                // Instruct Valet to remove isolation
                try await site.unisolate()
                // Reload the UI
                self.reloadSelectedRow()
            } catch {
                // Notify the user about a failed command
                let error = error as! ValetInteractionError
                self.notifyAboutFailedSiteIsolation(command: error.command)
            }
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
                    await site.unlink()
                    await self.reloadDomainsWithoutUI()
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
                    await proxy.remove()
                    await self.reloadDomainsWithoutUI()
                }
            }
        )
    }

    @objc func useInTerminal() {
        guard let site = selectedSite else {
            return
        }

        guard let version = site.isolatedPhpVersion?.versionNumber else {
            return
        }

        self.notifyAboutUsingIsolatedPhpVersionInTerminal(version: version)
    }

    // MARK: - Alerts & Modals

    private func notifyAboutModifiedSecureStatus(domain: String, secured: Bool) {
        LocalNotification.send(
            title: "domain_list.alerts_status_changed.title".localized,
            subtitle: "domain_list.alerts_status_changed.desc"
                .localized(
                    // 1. The domain that was secured is listed
                    "\(domain).\(Valet.shared.config.tld)",
                    // 2. What the domain is is listed (secure / unsecure)
                    secured
                    ? "domain_list.alerts_status_secure".localized
                    : "domain_list.alerts_status_unsecure".localized
                ),
            preference: .notifyAboutSecureToggle
        )
    }

    private func notifyAboutUsingIsolatedPhpVersionInTerminal(version: VersionNumber) {
        BetterAlert()
            .withInformation(
                title: "domain_list.alerts_isolated_php_terminal.title".localized(version.short),
                subtitle: "domain_list.alerts_isolated_php_terminal.subtitle".localized(
                    "\(version.major)\(version.minor)",
                    version.short
                ),
                description: "domain_list.alerts_isolated_php_terminal.desc".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    private func notifyAboutFailedSecureStatus(command: String) {
        BetterAlert()
            .withInformation(
                title: "domain_list.alerts_status_not_changed.title".localized,
                subtitle: "domain_list.alerts_status_not_changed.desc".localized(command)
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }

    private func notifyAboutFailedSiteIsolation(command: String) {
        BetterAlert()
            .withInformation(
                title: "domain_list.alerts_isolation_failed.title".localized,
                subtitle: "domain_list.alerts_isolation_failed.subtitle".localized,
                description: "domain_list.alerts_isolation_failed.desc".localized(command)
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
    }
}
