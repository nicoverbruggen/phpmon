//
//  MainMenu+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/05/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAlert

extension MainMenu {
    // MARK: - Actions

    @MainActor @objc func linkPhpBinary() {
        Task {
            await actions.linkPhp()
        }
    }

    @MainActor @objc func displayUnlinkedInfo() {
        Task { @MainActor in
            NVAlert()
                .withInformation(
                    title: "phpman.unlinked.title".localized,
                    subtitle: "phpman.unlinked.desc".localized,
                    description: "phpman.unlinked.detail".localized
                )
                .withPrimary(text: "generic.ok".localized)
                .show(urgency: .bringToFront)
        }
    }

    @MainActor @objc func fixHomebrewPermissions() {
        if !NVAlert()
            .withInformation(
                title: "alert.fix_homebrew_permissions.title".localized,
                subtitle: "alert.fix_homebrew_permissions.subtitle".localized,
                description: "alert.fix_homebrew_permissions.desc".localized
            )
                .withPrimary(text: "alert.fix_homebrew_permissions.ok".localized)
                .withSecondary(text: "alert.fix_homebrew_permissions.cancel".localized)
                .didSelectPrimary(urgency: .bringToFront) {
            return
        }

        asyncExecution {
            try self.actions.fixHomebrewPermissions()
        } success: {
            NVAlert()
                .withInformation(
                    title: "alert.fix_homebrew_permissions_done.title".localized,
                    subtitle: "alert.fix_homebrew_permissions_done.subtitle".localized,
                    description: "alert.fix_homebrew_permissions_done.desc".localized
                )
                .withPrimary(text: "generic.ok".localized)
                .show(urgency: .bringToFront)
        } failure: { error in
            NVAlert.show(for: error as! HomebrewPermissionError)
        }
    }

    @objc func restartPhpFpm() {
        Task { // Simple restart service
            await actions.restartPhpFpm()
        }
    }

    @objc func restartNginx() {
        Task { // Simple restart service
            await actions.restartNginx()
        }
    }

    @objc func restartDnsMasq() {
        Task { // Simple restart service
            await actions.restartDnsMasq()
        }
    }

    @MainActor @objc func restartValetServices() {
        Task { // Restart services and show notification
            await actions.restartDnsMasq()
            await actions.restartPhpFpm()
            await actions.restartNginx()

            LocalNotification.send(
                title: "notification.services_restarted".localized,
                subtitle: "notification.services_restarted_desc".localized,
                preference: .notifyAboutServices
            )
        }
    }

    @MainActor @objc func stopValetServices() {
        Task { // Stop services and show notification
            await actions.stopValetServices()

            LocalNotification.send(
                title: "notification.services_stopped".localized,
                subtitle: "notification.services_stopped_desc".localized,
                preference: .notifyAboutServices
            )
        }
    }

    @objc func disableAllXdebugModes() {
        guard let file = container.phpEnvs.getConfigFile(forKey: "xdebug.mode") else {
            Log.info("xdebug.mode could not be found in any .ini file, aborting.")
            return
        }

        do {
            try file.replace(key: "xdebug.mode", value: "off")

            Log.perf("Refreshing menu...")
            MainMenu.shared.rebuild()
            restartPhpFpm()
        } catch {
            Log.err("There was an issue replacing `xdebug.mode` in \(file.filePath)")
        }
    }

    @objc func toggleXdebugMode(sender: XdebugMenuItem) {
        Log.info("Switching Xdebug to mode: \(sender.mode)")

        guard let file = container.phpEnvs.getConfigFile(forKey: "xdebug.mode") else {
            return Log.info("xdebug.mode could not be found in any .ini file, aborting.")
        }

        do {
            var modes = Xdebug(container).activeModes

            if let index = modes.firstIndex(of: sender.mode) {
                modes.remove(at: index)
            } else {
                modes.append(sender.mode)
            }

            var newValue = modes.joined(separator: ",")
            if newValue.isEmpty {
                newValue = "off"
            }

            try file.replace(key: "xdebug.mode", value: newValue)

            Log.perf("Refreshing menu...")
            MainMenu.shared.rebuild()
            restartPhpFpm()
        } catch {
            Log.err("There was an issue replacing `xdebug.mode` in \(file.filePath)")
        }
    }

    @objc func toggleExtension(sender: ExtensionMenuItem) {
        Task { // Toggle extension async
            await sender.phpExtension?.toggle()

            if Preferences.isEnabled(.autoServiceRestartAfterExtensionToggle) {
                await actions.restartPhpFpm()
            }
        }
    }

    private func performRollback() {
        Task { // Rollback preset async
            await PresetHelper.rollbackPreset?.apply()
            PresetHelper.rollbackPreset = nil
            MainMenu.shared.rebuild()
        }
    }

    @MainActor @objc func rollbackPreset() {
        guard let preset = PresetHelper.rollbackPreset else {
            return
        }

        NVAlert().withInformation(
            title: "alert.revert_description.title".localized,
            subtitle: "alert.revert_description.subtitle".localized(
                preset.textDescription
            )
        )
        .withPrimary(text: "alert.revert_description.ok".localized, action: { alert in
            alert.close(with: .OK)
            self.performRollback()
        })
        .withSecondary(text: "alert.revert_description.cancel".localized)
        .show(urgency: .bringToFront)
    }

    @objc func togglePreset(sender: PresetMenuItem) {
        Task { // Apply preset async
            await sender.preset?.apply()
        }
    }

    @MainActor @objc func showPresetHelp() {
        NVAlert().withInformation(
            title: "preset_help_title".localized,
            subtitle: "preset_help_info".localized,
            description: "preset_help_desc".localized
        )
        .withPrimary(text: "generic.ok".localized)
        .withTertiary(text: "", action: { alert in
            NSWorkspace.shared.open(Constants.Urls.FrequentlyAskedQuestions)
            alert.close(with: .OK)
        })
        .show(urgency: .bringToFront)
    }

    @objc func openPhpInfo() {
        asyncWithBusyUI {
            Task { // Create temporary file and open the URL
                let url = await self.actions.createTempPhpInfoFile()
                NSWorkspace.shared.open(url)
            }
        }
    }

    @MainActor @objc func updateGlobalComposerDependencies() {
        ComposerWindow(container).updateGlobalDependencies(
            notify: true,
            completion: { _ in }
        )
    }

    @objc func openActiveConfigFolder() {
        guard let install = container.phpEnvs.phpInstall else {
            // TODO: Can't open the config if no PHP version is active
            return
        }

        if install.hasErrorState {
            actions.openGenericPhpConfigFolder()
            return
        }

        actions.openPhpConfigFolder(version: install.version.short)
    }

    @objc func openPhpMonitorConfigurationFile() {
        actions.openPhpMonitorConfigFile()
    }

    @objc func openGlobalComposerFolder() {
        actions.openGlobalComposerFolder()
    }

    @objc func openValetConfigFolder() {
        actions.openValetConfigFolder()
    }

    @objc func switchToPhpVersion(sender: PhpMenuItem) {
        self.switchToPhpVersion(sender.version)
    }

    public func switchToAnyPhpVersion(_ version: String, silently: Bool = false) {
        if silently {
            MainMenu.shared.shouldSwitchSilently = true
        }
        if container.phpEnvs.availablePhpVersions.contains(version) {
            Task { MainMenu.shared.switchToPhpVersion(version) }
        } else {
            Task { @MainActor in
                NVAlert().withInformation(
                    title: "alert.php_switch_unavailable.title".localized,
                    subtitle: "alert.php_switch_unavailable.subtitle".localized(version)
                ).withPrimary(
                    text: "alert.php_switch_unavailable.ok".localized
                ).show(urgency: .bringToFront)
            }
        }
    }

    func switchToPhpVersionAndWait(_ version: String, silently: Bool = false) async {
        if silently {
            MainMenu.shared.shouldSwitchSilently = true
        }

        if !container.phpEnvs.availablePhpVersions.contains(version) {
            Log.warn("This PHP version is currently unavailable, not switching!")
            return
        }

        container.phpEnvs.isBusy = true
        container.phpEnvs.delegate = self
        container.phpEnvs.delegate?.switcherDidStartSwitching(to: version)

        refreshIcon()
        rebuild()
        await PhpEnvironments.switcher.performSwitch(to: version)

        container.phpEnvs.currentInstall = ActivePhpInstallation(container)
        App.shared.handlePhpConfigWatcher()
        container.phpEnvs.delegate?.switcherDidCompleteSwitch(to: version)
    }

    @objc func switchToPhpVersion(_ version: String) {
        container.phpEnvs.isBusy = true
        container.phpEnvs.delegate = self
        container.phpEnvs.delegate?.switcherDidStartSwitching(to: version)

        Task(priority: .userInitiated) { [unowned self] in
            refreshIcon()
            rebuild()
            await PhpEnvironments.switcher.performSwitch(to: version)

            container.phpEnvs.currentInstall = ActivePhpInstallation(container)
            App.shared.handlePhpConfigWatcher()
            container.phpEnvs.delegate?.switcherDidCompleteSwitch(to: version)
        }
    }

    // MARK: - Async

    /**
     This async-friendly version of the switcher can be invoked elsewhere in the app:
     ```
    await MainMenu.shared.switchToPhp("8.1")
    // thing to do after the switch
     ```
     */
    func switchToPhp(_ version: String) async {
        Task { @MainActor [self] in
            container.phpEnvs.isBusy = true
            container.phpEnvs.delegate = self
            container.phpEnvs.delegate?.switcherDidStartSwitching(to: version)
        }

        refreshIcon()
        rebuild()
        await PhpEnvironments.switcher.performSwitch(to: version)

        container.phpEnvs.currentInstall = ActivePhpInstallation(container)
        App.shared.handlePhpConfigWatcher()
        container.phpEnvs.delegate?.switcherDidCompleteSwitch(to: version)
    }

}
