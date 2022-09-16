//
//  PreferenceName.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

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
    case showPhpDoctorSuggestions = "show_php_doctor_suggestions"

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

    // MENU CUSTOMIZATION
    case displayGlobalVersionSwitcher = "display_global_version_switcher"
    case displayServicesManager = "display_services_manager"
    case displayValetIntegration = "display_valet_integration"
    case displayPhpConfigFinder = "display_php_config_finder"
    case displayComposerToolkit = "display_composer_toolkit"
    case displayLimitsWidget = "display_limits_widget"
    case displayExtensions = "display_extensions"
    case displayPresets = "display_presets"
    case displayMisc = "display_misc"

    /**
     What type of data each preference contains.
     */
    static var mapping: [PreferenceType: [PreferenceName]] = [
        .boolean: [
            // Preferences
            .shouldDisplayDynamicIcon,
            .fullPhpVersionDynamicIcon,
            .autoServiceRestartAfterExtensionToggle,
            .autoComposerGlobalUpdateAfterSwitch,
            .allowProtocolForIntegrations,
            .automaticBackgroundUpdateCheck,
            .showPhpDoctorSuggestions,

            // Notifications
            .notifyAboutVersionChange,
            .notifyAboutPhpFpmRestart,
            .notifyAboutServices,
            .notifyAboutPresets,
            .notifyAboutSecureToggle,
            .notifyAboutGlobalComposerStatus,

            // UI Preferences
            .displayGlobalVersionSwitcher,
            .displayServicesManager,
            .displayValetIntegration,
            .displayPhpConfigFinder,
            .displayComposerToolkit,
            .displayLimitsWidget,
            .displayExtensions,
            .displayPresets,
            .displayMisc
        ],
        .string: [
            .globalHotkey,
            .iconTypeToDisplay
        ]
    ]
}

enum PreferenceType {
    case boolean, string
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
