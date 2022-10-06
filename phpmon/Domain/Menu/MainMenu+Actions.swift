//
//  MainMenu+Actions.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension MainMenu {

    // MARK: - Actions

    @objc func fixHomebrewPermissions() {
        if !BetterAlert()
            .withInformation(
                title: "alert.fix_homebrew_permissions.title".localized,
                subtitle: "alert.fix_homebrew_permissions.subtitle".localized,
                description: "alert.fix_homebrew_permissions.desc".localized
            )
                .withPrimary(text: "alert.fix_homebrew_permissions.ok".localized)
                .withSecondary(text: "alert.fix_homebrew_permissions.cancel".localized)
                .didSelectPrimary() {
            return
        }

        asyncExecution {
            try Actions.fixHomebrewPermissions()
        } success: {
            BetterAlert()
                .withInformation(
                    title: "alert.fix_homebrew_permissions_done.title".localized,
                    subtitle: "alert.fix_homebrew_permissions_done.subtitle".localized,
                    description: "alert.fix_homebrew_permissions_done.desc".localized
                )
                .withPrimary(text: "OK")
                .show()
        } failure: { error in
            BetterAlert.show(for: error as! HomebrewPermissionError)
        }
    }

    @objc func restartPhpFpm() {
        Task { // Simple restart service
            await Actions.restartPhpFpm()
        }
    }

    @MainActor @objc func restartValetServices() {
        Task { // Restart services and show notification
            await Actions.restartDnsMasq()
            await Actions.restartPhpFpm()
            await Actions.restartNginx()

            LocalNotification.send(
                title: "notification.services_restarted".localized,
                subtitle: "notification.services_restarted_desc".localized,
                preference: .notifyAboutServices
            )
        }
    }

    @MainActor @objc func stopValetServices() {
        Task { // Stop services and show notification
            await Actions.stopValetServices()

            LocalNotification.send(
                title: "notification.services_stopped".localized,
                subtitle: "notification.services_stopped_desc".localized,
                preference: .notifyAboutServices
            )
        }
    }

    @objc func restartNginx() {
        Task {
            await Actions.restartNginx()
        }
    }

    @objc func restartDnsMasq() {
        Task {
            await Actions.restartDnsMasq()
        }
    }

    @objc func disableAllXdebugModes() {
        guard let file = PhpEnv.shared.getConfigFile(forKey: "xdebug.mode") else {
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

        guard let file = PhpEnv.shared.getConfigFile(forKey: "xdebug.mode") else {
            return Log.info("xdebug.mode could not be found in any .ini file, aborting.")
        }

        do {
            var modes = Xdebug.activeModes

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
        Task {
            await sender.phpExtension?.toggle()

            if Preferences.isEnabled(.autoServiceRestartAfterExtensionToggle) {
                await Actions.restartPhpFpm()
            }
        }
    }

    private func performRollback() {
        Task {
            await PresetHelper.rollbackPreset?.apply()
            PresetHelper.rollbackPreset = nil
            MainMenu.shared.rebuild()
        }
    }

    @MainActor @objc func rollbackPreset() {
        guard let preset = PresetHelper.rollbackPreset else {
            return
        }

        BetterAlert().withInformation(
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
        .show()
    }

    @objc func togglePreset(sender: PresetMenuItem) {
        Task {
            await sender.preset?.apply()
        }
    }

    @MainActor @objc func showPresetHelp() {
        BetterAlert().withInformation(
            title: "preset_help_title".localized,
            subtitle: "preset_help_info".localized,
            description: "preset_help_desc".localized
        )
        .withPrimary(text: "OK")
        .withTertiary(text: "", action: { alert in
            NSWorkspace.shared.open(Constants.Urls.FrequentlyAskedQuestions)
            alert.close(with: .OK)
        })
        .show()
    }

    @objc func openPhpInfo() {
        asyncWithBusyUI {
            Task {
                let url = await Actions.createTempPhpInfoFile()
                NSWorkspace.shared.open(url)
            }
        }
    }

    @MainActor @objc func updateGlobalComposerDependencies() {
        ComposerWindow().updateGlobalDependencies(
            notify: true,
            completion: { _ in }
        )
    }

    @objc func openActiveConfigFolder() {
        if PhpEnv.phpInstall.hasErrorState {
            Actions.openGenericPhpConfigFolder()
            return
        }

        Actions.openPhpConfigFolder(version: PhpEnv.phpInstall.version.short)
    }

    @objc func openPhpMonitorConfigurationFile() {
        Actions.openPhpMonitorConfigFile()
    }

    @objc func openGlobalComposerFolder() {
        Actions.openGlobalComposerFolder()
    }

    @objc func openValetConfigFolder() {
        Actions.openValetConfigFolder()
    }

    @objc func switchToPhpVersion(sender: PhpMenuItem) {
        self.switchToPhpVersion(sender.version)
    }

    @objc func switchToPhpVersion(_ version: String) {
        setBusyImage()
        PhpEnv.shared.isBusy = true
        PhpEnv.shared.delegate = self
        PhpEnv.shared.delegate?.switcherDidStartSwitching(to: version)

        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            updatePhpVersionInStatusBar()
            rebuild()
            PhpEnv.switcher.performSwitch(
                to: version,
                completion: {
                    PhpEnv.shared.currentInstall = ActivePhpInstallation()
                    App.shared.handlePhpConfigWatcher()
                    PhpEnv.shared.delegate?.switcherDidCompleteSwitch(to: version)
                }
            )
        }
    }

    // MARK: - Async

    /**
     This async-friendly version of the switcher can be invoked elsewhere in the app:
     ```
     Task {
        await MainMenu.shared.switchToPhp("8.1")
        // thing to do after the switch
     }
     ```
     Since this async function uses `withCheckedContinuation`
     any code after will run only after the switcher is done.
     */
    func switchToPhp(_ version: String) async {
        DispatchQueue.main.async { [self] in
            setBusyImage()
            PhpEnv.shared.isBusy = true
            PhpEnv.shared.delegate = self
            PhpEnv.shared.delegate?.switcherDidStartSwitching(to: version)
        }

        return await withCheckedContinuation({ continuation in
            updatePhpVersionInStatusBar()
            rebuild()
            PhpEnv.switcher.performSwitch(
                to: version,
                completion: {
                    PhpEnv.shared.currentInstall = ActivePhpInstallation()
                    App.shared.handlePhpConfigWatcher()
                    PhpEnv.shared.delegate?.switcherDidCompleteSwitch(to: version)
                    continuation.resume()
                }
            )
        })
    }

}
