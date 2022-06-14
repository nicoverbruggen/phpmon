//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 These are the keys used for every preference in the app.
 */
enum PreferenceName: String {
    // FIRST-TIME LAUNCH
    case wasLaunchedBefore = "launched_before"

    // GENERAL
    case autoServiceRestartAfterExtensionToggle = "auto_restart_after_extension_toggle"
    case autoComposerGlobalUpdateAfterSwitch = "auto_composer_global_update_after_switch"
    case allowProtocolForIntegrations = "allow_protocol_for_integrations"
    case globalHotkey = "global_hotkey"
    case automaticBackgroundUpdateCheck = "backgroundUpdateCheck"

    // APPEARANCE
    case shouldDisplayDynamicIcon = "use_dynamic_icon"
    case iconTypeToDisplay = "icon_type_to_display"
    case fullPhpVersionDynamicIcon = "full_php_in_menu_bar"

    // NOTIFICATIONS
    case notifyAboutVersionChange = "notify_about_version_change"
    case notifyAboutPhpFpmRestart = "notify_about_php_fpm_restart"
    case notifyAboutServices = "notify_about_services_restart"
    case notifyAboutPresets = "notify_about_presets"
    case notifyAboutSecureToggle = "notify_about_secure_toggle"
    case notifyAboutGlobalComposerStatus = "notify_about_composer_status"
}

/**
 These are retired preferences that, if present, should be migrated.
 */
enum RetiredPreferenceName: String {
    case shouldDisplayPhpHintInIcon = "add_php_to_icon"
}

/**
 These are internal stats. They NEVER get shared.
 */
enum InternalStats: String {
    case launchCount = "times_launched"
    case switchCount = "times_switched_versions"
    case didSeeSponsorEncouragement = "did_see_sponsor_encouragement"
}

class Preferences {

    // MARK: - Singleton

    static var shared = Preferences()

    var customPreferences: CustomPrefs

    var cachedPreferences: [PreferenceName: Any?]

    public init() {
        Preferences.handleFirstTimeLaunch()
        cachedPreferences = Self.cache()
        customPreferences = CustomPrefs(scanApps: [], presets: [], services: [])
        loadCustomPreferences()
    }

    // MARK: - First Time Run

    /**
     Note: macOS seems to cache plist values in memory as well as in files.
     You can find the persisted configuration file in: ~/Library/Preferences/com.nicoverbruggen.phpmon.plist
     
     To clear the cache, and get a first-run experience you may need to run:
     ```
     defaults delete com.nicoverbruggen.phpmon
     killall cfprefsd
     ```
     */
    static func handleFirstTimeLaunch() {
        UserDefaults.standard.register(defaults: [
            /// Preferences: General
            PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue: true,
            PreferenceName.autoComposerGlobalUpdateAfterSwitch.rawValue: false,
            PreferenceName.allowProtocolForIntegrations.rawValue: true,
            PreferenceName.automaticBackgroundUpdateCheck.rawValue: true,

            /// Preferences: Appearance
            PreferenceName.shouldDisplayDynamicIcon.rawValue: true,
            PreferenceName.iconTypeToDisplay.rawValue: MenuBarIcon.iconPhp.rawValue,
            PreferenceName.fullPhpVersionDynamicIcon.rawValue: false,

            /// Preferences: Notifications
            PreferenceName.notifyAboutVersionChange.rawValue: true,
            PreferenceName.notifyAboutPhpFpmRestart.rawValue: true,
            PreferenceName.notifyAboutServices.rawValue: true,
            PreferenceName.notifyAboutPresets.rawValue: true,
            PreferenceName.notifyAboutSecureToggle.rawValue: true,
            PreferenceName.notifyAboutGlobalComposerStatus.rawValue: true,

            /// Stats
            InternalStats.switchCount.rawValue: 0,
            InternalStats.launchCount.rawValue: 0,
            InternalStats.didSeeSponsorEncouragement.rawValue: false
        ])

        if UserDefaults.standard.bool(forKey: PreferenceName.wasLaunchedBefore.rawValue) {
            handleMigration()
            return
        }

        Log.info("Saving first-time preferences!")
        UserDefaults.standard.setValue(true, forKey: PreferenceName.wasLaunchedBefore.rawValue)
        UserDefaults.standard.synchronize()
    }

    /**
     Sometimes preferences will change, and a migration is required to take the user's previous preference
     and migrate it over to the new type. For example, the choice to disable the icon next to the version
     number was once a boolean (do you want the icon? yes / no) but has now become a multi-faceted option.
     */
    static func handleMigration() {
        // If the user chose the "no icon" option, migrate it over
        if
            UserDefaults.standard.value(forKey: RetiredPreferenceName.shouldDisplayPhpHintInIcon.rawValue) != nil &&
            UserDefaults.standard.bool(forKey: RetiredPreferenceName.shouldDisplayPhpHintInIcon.rawValue) == false {
            Log.info("The preference where the user chose no icon has been migrated over.")
            UserDefaults.standard.set(MenuBarIcon.noIcon.rawValue, forKey: PreferenceName.iconTypeToDisplay.rawValue)
            UserDefaults.standard.removeObject(forKey: RetiredPreferenceName.shouldDisplayPhpHintInIcon.rawValue)
        }
    }

    // MARK: - API

    static var preferences: [PreferenceName: Any?] {
        return Self.shared.cachedPreferences
    }

    static var custom: CustomPrefs {
        return Self.shared.customPreferences
    }

    /**
     Determine whether a particular preference is enabled.
     - Important: Requires the preference to have a corresponding boolean value, or a fatal error will be thrown.
     */
    static func isEnabled(_ preference: PreferenceName) -> Bool {
        if let bool = Preferences.preferences[preference] as? Bool {
            return bool == true
        } else {
            fatalError("\(preference) is not a valid boolean preference!")
        }
    }

    // MARK: - Internal Functionality

    private static func cache() -> [PreferenceName: Any] {
        return [
            // Part 1: Always Booleans
            .shouldDisplayDynamicIcon:
                UserDefaults.standard.bool(
                forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue) as Any,
            .fullPhpVersionDynamicIcon: UserDefaults.standard.bool(
                forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue) as Any,
            .autoServiceRestartAfterExtensionToggle: UserDefaults.standard.bool(
                forKey: PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue) as Any,
            .autoComposerGlobalUpdateAfterSwitch: UserDefaults.standard.bool(
                forKey: PreferenceName.autoComposerGlobalUpdateAfterSwitch.rawValue) as Any,
            .allowProtocolForIntegrations: UserDefaults.standard.bool(
                forKey: PreferenceName.allowProtocolForIntegrations.rawValue) as Any,
            .automaticBackgroundUpdateCheck: UserDefaults.standard.bool(
                forKey: PreferenceName.automaticBackgroundUpdateCheck.rawValue) as Any,

            .notifyAboutVersionChange: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutVersionChange.rawValue) as Any,
            .notifyAboutPhpFpmRestart: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutPhpFpmRestart.rawValue) as Any,
            .notifyAboutServices: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutServices.rawValue) as Any,
            .notifyAboutPresets: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutPresets.rawValue) as Any,
            .notifyAboutSecureToggle: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutSecureToggle.rawValue) as Any,
            .notifyAboutGlobalComposerStatus: UserDefaults.standard.bool(
                forKey: PreferenceName.notifyAboutGlobalComposerStatus.rawValue) as Any,

            // Part 2: Always Strings
            .globalHotkey: UserDefaults.standard.string(
                forKey: PreferenceName.globalHotkey.rawValue) as Any,
            .iconTypeToDisplay: UserDefaults.standard.string(
                forKey: PreferenceName.iconTypeToDisplay.rawValue) as Any
        ]
    }

    static func update(_ preference: PreferenceName, value: Any?) {
        if value == nil {
            UserDefaults.standard.removeObject(forKey: preference.rawValue)
        } else {
            UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        }
        UserDefaults.standard.synchronize()

        // Update the preferences cache in memory!
        Preferences.shared.cachedPreferences = Preferences.cache()
    }

    // MARK: - Custom Preferences

    private func loadCustomPreferences() {
        // Ensure the configuration directory is created if missing
        Shell.run("mkdir -p ~/.config/phpmon")

        // Move the legacy file
        moveOutdatedConfigurationFile()

        // Attempt to load the file if it exists
        let url = URL(fileURLWithPath: "/Users/\(Paths.whoami)/.config/phpmon/config.json")
        if Filesystem.fileExists(url.path) {

            Log.info("A custom ~/.config/phpmon/config.json file was found. Attempting to parse...")
            loadCustomPreferencesFile(url)
        } else {
            Log.info("There was no /.config/phpmon/config.json file to be loaded.")
        }
    }

    private func moveOutdatedConfigurationFile() {
        if Filesystem.fileExists("~/.phpmon.conf.json") && !Filesystem.fileExists("~/.config/phpmon/config.json") {
            Log.info("An outdated configuration file was found. Moving it...")
            Shell.run("mv ~/.phpmon.conf.json ~/.config/phpmon/config.json")
            Log.info("The configuration file was moved successfully!")
        }
    }

    private func loadCustomPreferencesFile(_ url: URL) {
        do {
            customPreferences = try JSONDecoder().decode(
                CustomPrefs.self,
                from: try! String(contentsOf: url, encoding: .utf8).data(using: .utf8)!
            )

            Log.info("The ~/.config/phpmon/config.json file was successfully parsed.")

            if customPreferences.hasPresets() {
                Log.info("There are \(customPreferences.presets!.count) custom presets.")
            }

            if customPreferences.hasServices() {
                Log.info("There are custom services: \(customPreferences.services!)")
            }
        } catch {
            Log.warn("The ~/.config/phpmon/config.json file seems to be missing or malformed.")
        }
    }

}
