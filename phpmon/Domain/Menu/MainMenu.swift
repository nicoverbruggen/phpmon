//
//  MainMenu.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

@MainActor
class MainMenu: NSObject, NSWindowDelegate, NSMenuDelegate, PhpSwitcherDelegate {

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
     Rebuilds the menu (either asynchronously or synchronously).
     Defaults to rebuilding the menu asynchronously.
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
        if !PhpEnvironments.shared.isBusy {
            PhpEnvironments.shared.currentInstall = ActivePhpInstallation.load()
            updatePhpVersionInStatusBar()
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
            BetterAlert().withInformation(
                title: "startup.unsupported_versions_explanation.title".localized,
                subtitle: "startup.unsupported_versions_explanation.subtitle".localized(
                    PhpEnvironments.shared.incompatiblePhpVersions
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
            if PhpEnvironments.shared.isBusy {
                Log.perf("Refreshing icon: currently busy")
                setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIcon"))!)
            } else {
                Log.perf("Refreshing icon: no longer busy")
                if Preferences.preferences[.shouldDisplayDynamicIcon] as! Bool == false {
                    // Static icon has been requested
                    setStatusBar(image: NSImage(named: NSImage.Name("StatusBarIconStatic"))!)
                } else {
                    // The dynamic icon has been requested
                    let long = Preferences.preferences[.fullPhpVersionDynamicIcon] as! Bool

                    guard let install = PhpEnvironments.phpInstall else {
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
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }

    @objc func openLiteModeInfo() {
        Task { @MainActor in
            BetterAlert().withInformation(
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

        // Exit early if Valet is not detected (i.e. standalone mode)
        if !Valet.installed {
            return
        }

        Task { // Reload Homebrew services information asynchronously, but only if Valet is enabled
            await ServicesManager.shared.reloadServicesStatus()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        // When the menu is closed, allow the shortcut to work again
        App.shared.shortcutHotkey?.isPaused = false
    }
}
