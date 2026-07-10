//
//  SettingsTabViews.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

/**
 The classic settings tab container: a fixed-width, leading-aligned vertical
 stack of rows with 15pt of vertical padding, matching the old storyboard's
 template stack view.
 */
struct SettingsTabContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(.vertical, 15)
        .frame(width: SettingsRowMetrics.rowWidth)
    }
}

// MARK: - General

struct GeneralSettingsView: View {
    var body: some View {
        SettingsTabContainer {
            SettingsPickerRow(
                sectionKey: "prefs.language",
                descriptionKey: "prefs.language_options_desc",
                options: Self.languageOptions,
                preference: .languageOverride,
                action: {
                    PreferencesWindowController.handleLanguageChange()
                }
            )

            SettingsToggleRow(
                sectionKey: "prefs.php_doctor",
                titleKey: "prefs.php_doctor_suggestions_title",
                descriptionKey: "prefs.php_doctor_suggestions_desc",
                preference: .showPhpDoctorSuggestions,
                action: {
                    MainMenu.shared.refreshIcon()
                    MainMenu.shared.rebuild()
                }
            )

            SettingsToggleRow(
                sectionKey: "prefs.services",
                titleKey: "prefs.auto_restart_services_title",
                descriptionKey: "prefs.auto_restart_services_desc",
                preference: .autoServiceRestartAfterExtensionToggle
            )

            SettingsToggleRow(
                sectionKey: "prefs.switcher",
                titleKey: "prefs.auto_composer_update_title",
                descriptionKey: "prefs.auto_composer_update_desc",
                preference: .autoComposerGlobalUpdateAfterSwitch
            )

            SettingsHotkeyRow()

            SettingsToggleRow(
                sectionKey: "prefs.integrations",
                titleKey: "prefs.open_protocol_title",
                descriptionKey: "prefs.open_protocol_desc",
                preference: .allowProtocolForIntegrations
            )

            SettingsToggleRow(
                sectionKey: "prefs.updates",
                titleKey: "prefs.automatic_update_check_title",
                descriptionKey: "prefs.automatic_update_check_desc",
                preference: .automaticBackgroundUpdateCheck
            )

            SettingsLoginItemRow()
        }
    }

    /**
     All languages the app ships with, plus the "System Default" option,
     mirroring the options offered by the previous implementation.
     */
    private static var languageOptions: [PreferenceDropdownOption] {
        var options = Bundle.main.localizations
            .filter({ $0 != "Base" })
            .map({ lang in
                return PreferenceDropdownOption(
                    label: Locale.current.localizedString(forLanguageCode: lang)!,
                    value: lang
                )
            })

        options.insert(PreferenceDropdownOption(label: "System Default", value: ""), at: 0)

        return options
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    var body: some View {
        SettingsTabContainer {
            SettingsToggleRow(
                sectionKey: "prefs.dynamic_icon",
                titleKey: "prefs.dynamic_icon_title",
                descriptionKey: "prefs.dynamic_icon_desc",
                preference: .shouldDisplayDynamicIcon,
                action: {
                    MainMenu.shared.refreshIcon()
                }
            )

            SettingsPickerRow(
                sectionKey: nil,
                descriptionKey: "prefs.icon_options_desc",
                options: MenuBarIcon.allCases.map {
                    PreferenceDropdownOption(label: $0.rawValue, value: $0.rawValue)
                },
                localizationPrefix: "prefs.icon_options",
                preference: .iconTypeToDisplay,
                action: {
                    MainMenu.shared.refreshIcon()
                }
            )

            SettingsToggleRow(
                sectionKey: "prefs.info_density",
                titleKey: "prefs.display_full_php_version",
                descriptionKey: "prefs.display_full_php_version_desc",
                preference: .fullPhpVersionDynamicIcon,
                action: {
                    MainMenu.shared.refreshIcon()
                    MainMenu.shared.rebuild()
                }
            )

            SettingsToggleRow(
                sectionKey: "prefs.hide_auto_detected_services",
                titleKey: "prefs.hide_auto_detected_services_title",
                descriptionKey: "prefs.hide_auto_detected_services_desc",
                preference: .hideAutoDetectedServicesInMenu,
                action: {
                    Task { @MainActor in
                        // Reload all services
                        await ServicesManager.shared.reloadServicesStatus()
                        // Rebuild the menu immediately
                        MainMenu.shared.rebuildImmediately()
                    }
                }
            )
        }
    }
}

// MARK: - Menu Structure (Visibility)

struct MenuStructureSettingsView: View {
    private struct Feature {
        let key: String
        let preference: PreferenceName
        var condition: Bool = true
    }

    /// The menu features that can be toggled, in the same order as before.
    /// The `condition` mirrors the old `addView(when:)` behavior.
    private var features: [Feature] {
        [
            Feature(key: "prefs.display_global_version_switcher", preference: .displayGlobalVersionSwitcher),
            Feature(key: "prefs.display_services_manager", preference: .displayServicesManager,
                    condition: Valet.installed),
            Feature(key: "prefs.display_valet_integration", preference: .displayValetIntegration,
                    condition: Valet.installed),
            Feature(key: "prefs.display_php_config_finder", preference: .displayPhpConfigFinder),
            Feature(key: "prefs.display_composer_toolkit", preference: .displayComposerToolkit),
            Feature(key: "prefs.display_limits_widget", preference: .displayLimitsWidget),
            Feature(key: "prefs.display_extensions", preference: .displayExtensions),
            Feature(key: "prefs.display_presets", preference: .displayPresets),
            Feature(key: "prefs.display_misc", preference: .displayMisc),
            Feature(key: "prefs.display_driver", preference: .displayDriver)
        ]
    }

    var body: some View {
        let visible = features.filter(\.condition)

        SettingsTabContainer {
            ForEach(Array(visible.enumerated()), id: \.element.key) { index, feature in
                SettingsToggleRow(
                    sectionKey: index == 0 ? "prefs.menu_contents" : nil,
                    titleKey: feature.key,
                    descriptionKey: "\(feature.key)_desc",
                    preference: feature.preference,
                    action: {
                        MainMenu.shared.refreshIcon()
                        MainMenu.shared.rebuild()
                    }
                )
            }
        }
    }
}

// MARK: - Notifications

struct NotificationsSettingsView: View {
    var body: some View {
        SettingsTabContainer {
            SettingsToggleRow(
                sectionKey: "prefs.notifications",
                titleKey: "prefs.notify_about_version_change",
                descriptionKey: "prefs.notify_about_version_change_desc",
                preference: .notifyAboutVersionChange
            )
            SettingsToggleRow(
                titleKey: "prefs.notify_about_presets",
                descriptionKey: "prefs.notify_about_presets_desc",
                preference: .notifyAboutPresets
            )
            if Valet.installed {
                SettingsToggleRow(
                    titleKey: "prefs.notify_about_secure_status",
                    descriptionKey: "prefs.notify_about_secure_status_desc",
                    preference: .notifyAboutSecureToggle
                )
            }
            SettingsToggleRow(
                titleKey: "prefs.notify_about_composer_success",
                descriptionKey: "prefs.notify_about_composer_success_desc",
                preference: .notifyAboutGlobalComposerStatus
            )
            SettingsToggleRow(
                titleKey: "prefs.notify_about_services",
                descriptionKey: "prefs.notify_about_services_desc",
                preference: .notifyAboutServices
            )
            if Valet.installed {
                SettingsToggleRow(
                    titleKey: "prefs.notify_about_php_fpm_change",
                    descriptionKey: "prefs.notify_about_php_fpm_change_desc",
                    preference: .notifyAboutPhpFpmRestart
                )
            }
            if Valet.installed {
                SettingsToggleRow(
                    sectionKey: "prefs.warnings",
                    titleKey: "prefs.warn_about_non_standard_tld",
                    descriptionKey: "prefs.warn_about_non_standard_tld_desc",
                    preference: .warnAboutNonStandardTLD
                )
            }
        }
    }
}
