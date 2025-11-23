//
//  MainMenu.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAlert

@MainActor
class MainMenu: NSObject, NSWindowDelegate, NSMenuDelegate, PhpSwitcherDelegate {
    var container: Container {
        return App.shared.container
    }

    var actions: Actions {
        return Actions(container)
    }

    static let shared = MainMenu()

    override init() {
        super.init()
        statusItem.isVisible = !isRunningSwiftUIPreview
    }

    weak var menuDelegate: NSMenuDelegate?

    /**
     The status bar item with variable length.
     */
    let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )

    // MARK: - State Variables

    /**
     You can instruct the app to switch to a given PHP version silently.
     That will toggle this flag to true. Upon switching, this flag will be reset.
     */
    var shouldSwitchSilently: Bool = false

    // MARK: - UI related

    /**
     Rebuilds the menu on the main thread.
     */
    func rebuild() {
        Task { @MainActor [self] in
            let menu = StatusMenu()
            menu.addMenuItems()
            menu.items.forEach({ (item) in
                item.target = self
            })
            statusItem.menu = menu
            statusItem.menu?.delegate = self
        }
    }

    /**
     Sets the status bar image based on a version string.
     */
    func setStatusBarImage(version: String) {
        setStatusBar(
            image: (Preferences.preferences[.iconTypeToDisplay] as! String != MenuBarIcon.noIcon.rawValue)
                ? MenuBarImageGenerator.textToImageWithIcon(text: version)
                : MenuBarImageGenerator.textToImage(text: version)
        )
    }

    /**
     Sets the status bar image, based on the provided NSImage.
     The image will be used as a template image.
     */
    func setStatusBar(image: NSImage) {
        if let button = statusItem.button {
            image.isTemplate = true
            button.image = image
        }
    }

    // MARK: - User Interface

    /** Reloads which PHP versions is currently active. */
    @objc func refreshActiveInstallation() {
        if !container.phpEnvs.isBusy {
            container.phpEnvs.currentInstall = ActivePhpInstallation.load(container)
            refreshIcon()
            rebuild()
        } else {
            Log.perf("Skipping version refresh due to busy status!")
        }
    }

    /** Updates the icon (refresh icon) and rebuilds the menu. */
    @available(*, deprecated, message: "Use the busy status instead")
    @objc func updatePhpVersionInStatusBar() {
        refreshIcon()
        rebuild()
    }

    /**
     Reloads the menu in the foreground.
     This mimics the exact behaviours of `asyncExecution` as set in the method below.
     */
    @objc func reloadPhpMonitorMenuInForeground() {
        Log.perf("The menu will be reloaded...")
        Task { [self] in
            self.refreshActiveInstallation()
            self.refreshIcon()
            self.rebuild()
            await ServicesManager.shared.reloadServicesStatus()
            Log.perf("The menu has been reloaded!")
        }
    }

    /**
     Shows the Welcome Tour screen, again.
     Did this need a comment? No, probably not.
     */
    @objc func showWelcomeTour() {
        Task { @MainActor in
            OnboardingWindowController.show()
        }
    }

    @objc func showIncompatiblePhpVersionsAlert() {
        Task { @MainActor in
            NVAlert().withInformation(
                title: "startup.unsupported_versions_explanation.title".localized,
                subtitle: "startup.unsupported_versions_explanation.subtitle".localized(
                    container.phpEnvs.incompatiblePhpVersions
                        .map({ version in
                            return "• PHP \(version)"
                        })
                        .joined(separator: "\n")
                ),
                description: "startup.unsupported_versions_explanation.desc".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
        }
    }

    @objc func showValetUpgradeAvailableAlert() {
        ValetUpgrader.showUpgradeAlert()
    }

    /** Reloads the menu in the background, using `asyncExecution`. */
    @objc func reloadPhpMonitorMenuInBackground() {
        asyncExecution({
            // This automatically reloads the menu
            Log.perf("Reloading information about the PHP installation (in the background)...")
        }, behaviours: [
            .setsBusyUI,
            .reloadsPhpInstallation,
            .broadcastServicesUpdate,
            .updatesMenuBarContents
        ])
    }

    /** Refreshes the icon with the PHP version. */
    @objc func refreshIcon() {
        Task { @MainActor [self] in
            if container.phpEnvs.isBusy {
                Log.perf("Refreshing icon: currently busy")
                setStatusBar(image: NSImage.statusBarIcon)
            } else {
                Log.perf("Refreshing icon: no longer busy")
                if Preferences.preferences[.shouldDisplayDynamicIcon] as! Bool == false {
                    // Static icon has been requested
                    setStatusBar(image: NSImage.statusBarIconStatic)
                } else {
                    // The dynamic icon has been requested
                    let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool

                    guard let install = container.phpEnvs.phpInstall else {
                        setStatusBarImage(version: "???")
                        return
                    }

                    setStatusBarImage(version: long ? install.version.long : install.version.short)
                }
            }
        }
    }

    // MARK: - Menu Item Functionality

    @objc func openAbout() {
        if NSEvent.modifierFlags.contains(.option) && NSEvent.modifierFlags.contains(.command) {
            fatalError("Debug crash triggered via About menu with OPT+CMD.")
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel(self)
    }

    @objc func openLiteModeInfo() {
        Task { @MainActor in
            NVAlert().withInformation(
                title: "lite_mode_explanation.title".localized,
                subtitle: "lite_mode_explanation.subtitle".localized,
                description: "lite_mode_explanation.description".localized
            )
            .withPrimary(text: "generic.ok".localized)
            .show()
        }
    }

    @objc func openPrefs() {
        PreferencesWindowController.show()
    }

    @objc func openWarnings() {
        PhpDoctorWindowController.show()
    }

    @objc func openConfigGUI() {
        PhpConfigManagerWindowController.show()
    }

    @objc func openDomainList() {
        DomainListVC.show()
    }

    @objc func openPhpVersionManager() {
        PhpVersionManagerWindowController.show()
    }

    @objc func openPhpExtensionManager() {
        PhpExtensionManagerWindowController.show()
    }

    @objc func openDonate() {
        NSWorkspace.shared.open(Constants.Urls.DonationPage)
    }

    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc func checkForUpdates() {
        Task { await AppUpdater().checkForUpdates(userInitiated: true) }
    }

    // MARK: - Menu Delegate

    func menuWillOpen(_ menu: NSMenu) {
        // Make sure the shortcut key does not trigger this when the menu is open
        App.shared.shortcutHotkey?.isPaused = true

        // If Valet is installed, periodically refresh service data upon menu open!
        if Valet.installed && !lastInitiatedServicesReloadWasRecent() {
            // First, we need to update the timestamp
            lastInitiatedServicesReload = Date()

            Task { // Next up, dispatch the Homebrew services reload asynchronously
                await ServicesManager.shared.reloadServicesStatus()
            }
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        // When the menu is closed, allow the shortcut to work again
        App.shared.shortcutHotkey?.isPaused = false
    }

    // MARK: - Debounce for `ServicesManager`

    /**
     Tracks the last time services were reloaded to enable debouncing.
     */
    private var lastInitiatedServicesReload: Date?

    /**
     Returns true if the last reload was, indeed, too recent.
     */
    func lastInitiatedServicesReloadWasRecent() -> Bool {
        if let lastReload = lastInitiatedServicesReload {
            let timeSinceLastReload = Date().timeIntervalSince(lastReload)
            if timeSinceLastReload < .seconds(2) {
                Log.perf("Skipping services reload on menu open, too recent.")
                return true
            }
        }

        return false
    }
}
