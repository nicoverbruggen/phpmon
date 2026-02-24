//
//  PreferencesVC+WindowsRestore.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Cocoa

extension GenericPreferenceVC {
    struct WindowSnapshot {
        let name: String
        let frame: NSRect?
    }

    func captureOpenWindowsForLanguageSwitch() -> [WindowSnapshot] {
        App.shared.openWindows.compactMap { windowName in
            switch windowName {
            case "DomainList":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: DomainListWC.self)?.frame
                )
            case "Onboarding":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: OnboardingWC.self)?.frame
                )
            case "ConfigManager":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: PhpConfigManagerWC.self)?.frame
                )
            case "Warnings":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: PhpDoctorWC.self)?.frame
                )
            case "PhpVersionManager":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: PhpVersionManagerWC.self)?.frame
                )
            case "PhpExtensionManager":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: PhpExtensionManagerWC.self)?.frame
                )
            case "CommandHistory", "ActiveCommands":
                return WindowSnapshot(
                    name: windowName,
                    frame: WindowManager.window(for: CommandHistoryWC.self)?.frame
                )
            default:
                return nil
            }
        }
    }

    func reopenWindows(afterLanguageChange snapshots: [WindowSnapshot]) {
        for snapshot in snapshots {
            switch snapshot.name {
            case "DomainList":
                DomainListVC.show()
                applyFrame(snapshot.frame, for: DomainListWC.self)
            case "Onboarding":
                OnboardingWindowController.show()
                applyFrame(snapshot.frame, for: OnboardingWC.self)
            case "ConfigManager":
                PhpConfigManagerWindowController.show()
                applyFrame(snapshot.frame, for: PhpConfigManagerWC.self)
            case "Warnings":
                PhpDoctorWindowController.show()
                applyFrame(snapshot.frame, for: PhpDoctorWC.self)
            case "PhpVersionManager":
                PhpVersionManagerWindowController.show()
                applyFrame(snapshot.frame, for: PhpVersionManagerWC.self)
            case "PhpExtensionManager":
                PhpExtensionManagerWindowController.show()
                applyFrame(snapshot.frame, for: PhpExtensionManagerWC.self)
            case "CommandHistory", "ActiveCommands":
                CommandHistoryWindowController.show()
                applyFrame(snapshot.frame, for: CommandHistoryWC.self)
            default:
                continue
            }
        }
    }

    private func applyFrame<T: NSWindowController>(_ frame: NSRect?, for type: T.Type) {
        guard let frame else { return }
        WindowManager.window(for: type)?.setFrame(frame, display: true)
    }
}
