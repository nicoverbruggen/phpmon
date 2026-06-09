//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

class Preferences {
    var container: Container

    // MARK: - Preferences

    var customPreferences: CustomPrefs {
        get { _customPreferences.value }
        set { _customPreferences.value = newValue }
    }

    var cachedPreferences: [PreferenceName: Any?] {
        get { _cachedPreferences.value }
        set { _cachedPreferences.value = newValue }
    }

    private let _customPreferences: Locked<CustomPrefs>
    private let _cachedPreferences: Locked<[PreferenceName: Any?]>

    // MARK: - Initialization

    public init(container: Container) {
        self.container = container
        Preferences.handleFirstTimeLaunch()

        _cachedPreferences = Locked(Self.cache())
        _customPreferences = Locked(CustomPrefs(
            scanApps: [],
            presets: [],
            services: [],
            environmentVariables: [:]
        ))

        if isRunningSwiftUIPreview {
            return
        }
    }

    static func registerPreferenceDefaults(_ configuration: [PreferenceName: Any]) {
        let tuple = configuration.map { (key: PreferenceName, value: Any) in
            return (key.rawValue, value)
        }

        let defaults = Dictionary(uniqueKeysWithValues: tuple)
        UserDefaults.standard.register(defaults: defaults)
    }

    static func registerPersistentAppStateDefaults(_ configuration: [PersistentAppState: Any]) {
        let tuple = configuration.map { (key: PersistentAppState, value: Any) in
            return (key.rawValue, value)
        }

        let defaults = Dictionary(uniqueKeysWithValues: tuple)
        UserDefaults.standard.register(defaults: defaults)
    }

    static func registerInternalAppStateDefaults(_ configuration: [InternalStats: Any]) {
        let tuple = configuration.map { (key: InternalStats, value: Any) in
            return (key.rawValue, value)
        }

        let defaults = Dictionary(uniqueKeysWithValues: tuple)
        UserDefaults.standard.register(defaults: defaults)
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
        self.registerPreferenceDefaults([
            /// Preferences: General
            .autoServiceRestartAfterExtensionToggle: true,
            .autoComposerGlobalUpdateAfterSwitch: false,
            .allowProtocolForIntegrations: false,
            .automaticBackgroundUpdateCheck: true,
            .showPhpDoctorSuggestions: true,
            .languageOverride: "",

            /// Preferences: Appearance
            .shouldDisplayDynamicIcon: true,
            .iconTypeToDisplay: MenuBarIcon.iconPhp.rawValue,
            .fullPhpVersionDynamicIcon: false,
            .hideAutoDetectedServicesInMenu: true,

            /// Preferences: Notifications
            .warnAboutNonStandardTLD: true,
            .notifyAboutVersionChange: true,
            .notifyAboutPhpFpmRestart: true,
            .notifyAboutServices: true,
            .notifyAboutPresets: true,
            .notifyAboutSecureToggle: true,
            .notifyAboutGlobalComposerStatus: true,

            /// Preferences: UI Preferences
            .displayDriver: true,
            .displayGlobalVersionSwitcher: true,
            .displayServicesManager: true,
            .displayValetIntegration: true,
            .displayPhpConfigFinder: true,
            .displayComposerToolkit: true,
            .displayLimitsWidget: true,
            .displayExtensions: true,
            .displayPresets: true,
            .displayMisc: true
        ])

        registerPersistentAppStateDefaults([
            .lastAutomaticUpdateCheck: 0,
            .updateCheckFailureCount: 0
        ])

        registerInternalAppStateDefaults([
            .switchCount: 0,
            .launchCount: 0,
            .didSeeSponsorEncouragement: false,
            .lastGlobalPhpVersion: ""
        ])

        if UserDefaults.standard.bool(forKey: PersistentAppState.wasLaunchedBefore.rawValue) {
            handleMigration()
            return
        }

        Log.info("Saving first-time preferences!")
        UserDefaults.standard.setValue(true, forKey: PersistentAppState.wasLaunchedBefore.rawValue)
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
        return App.shared.container.preferences.cachedPreferences
    }

    static var custom: CustomPrefs {
        return App.shared.container.preferences.customPreferences
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

    static func update(_ preference: PreferenceName, value: Any?, notify: Bool = false) {
        if value == nil {
            UserDefaults.standard.removeObject(forKey: preference.rawValue)
        } else {
            UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        }
        UserDefaults.standard.synchronize()

        // Update the preferences cache in memory!
        App.shared.container.preferences.cachedPreferences = Preferences.cache()

        if notify {
            NotificationCenter.default.post(name: Events.PreferencesUpdated, object: nil)
        }
    }
}
