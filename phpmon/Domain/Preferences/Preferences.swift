//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class Preferences {

    // MARK: - Singleton

    static var shared = Preferences()

    var customPreferences: CustomPrefs

    var cachedPreferences: [PreferenceName: Any?]

    public init() {
        Preferences.handleFirstTimeLaunch()
        cachedPreferences = Self.cache()
        customPreferences = CustomPrefs(
            scanApps: [],
            presets: [],
            services: [],
            environmentVariables: [:]
        )
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
            PreferenceName.showPhpDoctorSuggestions.rawValue: true,

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

            /// Preferences: UI Preferences
            PreferenceName.displayGlobalVersionSwitcher.rawValue: true,
            PreferenceName.displayServicesManager.rawValue: true,
            PreferenceName.displayValetIntegration.rawValue: true,
            PreferenceName.displayPhpConfigFinder.rawValue: true,
            PreferenceName.displayComposerToolkit.rawValue: true,
            PreferenceName.displayLimitsWidget.rawValue: true,
            PreferenceName.displayExtensions.rawValue: true,
            PreferenceName.displayPresets.rawValue: true,
            PreferenceName.displayMisc.rawValue: true,

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

    private static func cache() -> [PreferenceName: Any?] {
        return Dictionary(uniqueKeysWithValues: PreferenceName.mapping
            .flatMap { (key: PreferenceType, value: [PreferenceName]) in
                value.map { preference -> (PreferenceName, Any?) in
                    return (preference, { () -> Any? in
                        switch key {
                        case .boolean: return UserDefaults.standard.bool(forKey: preference.rawValue)
                        case .string: return UserDefaults.standard.string(forKey: preference.rawValue)
                        }
                    }())
                }
        })
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
}
