//
//  MainMenu.swift
//  PHP Monitor
//
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAlert

@MainActor
class MainMenu: NSObject, NSWindowDelegate, PhpSwitcherDelegate {
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
        statusItem.button?.isEnabled = false

        // The status menu's open/close side effects are driven by the menu
        // *tracking* notifications rather than NSMenuDelegate: AppKit's
        // accessibility machinery "simulates opening" menus for inspection
        // (`_openForInspection`) and invokes delegate methods in a context
        // where Swift's main-actor executor checks crash (observed whenever an
        // accessibility client — including XCUITest — walked the status menu).
        // Tracking notifications fire only for genuine tracking sessions, on
        // the main thread.
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuDidBeginTracking(_:)),
            name: NSMenu.didBeginTrackingNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(menuDidEndTracking(_:)),
            name: NSMenu.didEndTrackingNotification, object: nil
        )
    }

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

    /// The menu being tracked can outlive a rebuild of `statusItem.menu`.
    private weak var trackingMenu: NSMenu?

    private var activeInstallationRefreshID: UUID?

    // MARK: - UI related

    /**
     Rebuilds the menu on the main thread.
     */
    func rebuild() {
        Task { @MainActor [self] in
            rebuildImmediately()
        }
    }

    @MainActor
    func rebuildImmediately() {
        let menu = StatusMenu()
        menu.addMenuItems()
        menu.items.forEach({ (item) in
            item.target = self
        })
        statusItem.menu = menu
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

    /**
     Dismisses the main menu if it's open.
     */
    func dismissMenu(animated: Bool = true) {
        if animated {
            self.statusItem.menu?.cancelTracking()
        } else {
            self.statusItem.menu?.cancelTrackingWithoutAnimation()
        }
    }

    // MARK: - User Interface

    /** Reloads which PHP versions is currently active. */
    func refreshActiveInstallation() async {
        if !container.phpEnvs.isBusy {
            let refreshID = UUID()
            activeInstallationRefreshID = refreshID
            let previousInstall = container.phpEnvs.currentInstall
            let install = await ActivePhpInstallation.load(container)

            // Only the latest refresh can publish, and a completed switch takes precedence.
            guard activeInstallationRefreshID == refreshID,
                  !container.phpEnvs.isBusy,
                  container.phpEnvs.currentInstall === previousInstall else { return }

            container.phpEnvs.currentInstall = install
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
            await self.refreshActiveInstallation()
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
            WelcomeTourWindowController.show()
        }
    }

    @objc func showCommandHistory() {
        Task { @MainActor in
            CommandHistoryWindowController.show()
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
            .show(urgency: .bringToFront)
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

                    guard let version = container.phpEnvs.phpInstall?.version else {
                        setStatusBarImage(version: "???")
                        return
                    }

                    setStatusBarImage(version: long ? version.long : version.short)
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
            let shouldInstallValet = NVAlert().withInformation(
                title: "lite_mode_explanation.title".localized,
                subtitle: "lite_mode_explanation.subtitle".localized,
                description: "lite_mode_explanation.description".localized
            )
            .withPrimary(text: "lite_mode_explanation.install_valet".localized)
            .withSecondary(text: "lite_mode_explanation.not_now".localized)
            .didSelectPrimary(urgency: .bringToFront)

            guard shouldInstallValet else {
                return
            }

            dismissMenu(animated: false)

            let startup = Startup(container)
            let outcome = await startup.showOnboardingWizard(
                exitsApplicationOnClose: false,
                flow: ValetInstallOnboardingFlow()
            )

            if outcome == .completed {
                await startup.refreshAfterInstallingValetViaOnboarding()
            }
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
        if !container.phpEnvs.cachedPhpInstallations.isEmpty {
            PhpVersionManagerWindowController.show()
        } else {
            Log.err("Skipping opening version manager due to no available PHP versions.")
        }
    }

    @objc func openPhpExtensionManager() {
        if !container.phpEnvs.cachedPhpInstallations.isEmpty {
            PhpExtensionManagerWindowController.show()
        } else {
            Log.err("Skipping opening extension manager due to no available PHP versions.")
        }
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

    // MARK: - Menu Tracking

    @objc private func menuDidBeginTracking(_ notification: Notification) {
        guard (notification.object as? NSMenu) === statusItem.menu else { return }

        trackingMenu = notification.object as? NSMenu

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

    @objc private func menuDidEndTracking(_ notification: Notification) {
        guard let menu = notification.object as? NSMenu, menu === trackingMenu else { return }

        trackingMenu = nil

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
