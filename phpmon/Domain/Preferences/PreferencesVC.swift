//
//  PreferencesVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import Carbon

class GenericPreferenceVC: NSViewController {

    // MARK: - Content

    @IBOutlet weak var stackView: NSStackView!

    var views: [NSView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.views.forEach({ self.stackView.addArrangedSubview($0) })
    }

    // MARK: - Deinitialization

    deinit {
        Log.perf("deinit: \(String(describing: self)).\(#function)")
    }

    func addView(when condition: Bool, _ view: NSView) -> GenericPreferenceVC {
        if condition {
            self.views.append(view)
        }

        return self
    }

    func getDynamicIconPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.dynamic_icon".localized,
            descriptionText: "prefs.dynamic_icon_desc".localized,
            checkboxText: "prefs.dynamic_icon_title".localized,
            preference: .shouldDisplayDynamicIcon,
            action: {
                MainMenu.shared.refreshIcon()
            }
        )
    }

    func getLanguageOptionsPV() -> NSView {
        var options = Bundle.main.localizations
            .filter({ $0 != "Base"})
            .map({ lang in
                return PreferenceDropdownOption(
                    label: Locale.current.localizedString(forLanguageCode: lang)!,
                    value: lang
                )
            })
        options.insert(PreferenceDropdownOption(label: "System Default", value: ""), at: 0)

        return SelectPreferenceView.make(
            sectionText: "prefs.language".localized,
            descriptionText: "prefs.language_options_desc".localized,
            options: options,
            preference: .languageOverride,
            action: {
                MainMenu.shared.refreshIcon()
            }
        )
    }

    func getIconOptionsPV() -> NSView {
        return SelectPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.icon_options_desc".localized,
            options: MenuBarIcon.allCases
                .map({ return PreferenceDropdownOption(label: $0.rawValue, value: $0.rawValue) }),
            localizationPrefix: "prefs.icon_options",
            preference: .iconTypeToDisplay,
            action: {
                MainMenu.shared.refreshIcon()
            }
        )
    }

    func getIconDensityPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.info_density".localized,
            descriptionText: "prefs.display_full_php_version_desc".localized,
            checkboxText: "prefs.display_full_php_version".localized,
            preference: .fullPhpVersionDynamicIcon,
            action: {
                MainMenu.shared.refreshIcon()
                MainMenu.shared.rebuild()
            }
        )
    }

    func getAutoRestartServicesPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.services".localized,
            descriptionText: "prefs.auto_restart_services_desc".localized,
            checkboxText: "prefs.auto_restart_services_title".localized,
            preference: .autoServiceRestartAfterExtensionToggle,
            action: {}
        )
    }

    func getAutomaticComposerUpdatePV() -> NSView {
        CheckboxPreferenceView.make(
            sectionText: "prefs.switcher".localized,
            descriptionText: "prefs.auto_composer_update_desc".localized,
            checkboxText: "prefs.auto_composer_update_title".localized,
            preference: .autoComposerGlobalUpdateAfterSwitch,
            action: {}
        )
    }

     func getShortcutPV() -> NSView {
         return HotkeyPreferenceView.make(
             sectionText: "prefs.global_shortcut".localized,
             descriptionText: "prefs.shortcut_desc".localized,
             self
        )
     }

    func getIntegrationsPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.integrations".localized,
            descriptionText: "prefs.open_protocol_desc".localized,
            checkboxText: "prefs.open_protocol_title".localized,
            preference: .allowProtocolForIntegrations,
            action: {}
        )
    }

    func getAutomaticUpdateCheckPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.updates".localized,
            descriptionText: "prefs.automatic_update_check_desc".localized,
            checkboxText: "prefs.automatic_update_check_title".localized,
            preference: .automaticBackgroundUpdateCheck,
            action: {}
        )
    }

    func getShowPhpDoctorSuggestionsPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.php_doctor".localized,
            descriptionText: "prefs.php_doctor_suggestions_desc".localized,
            checkboxText: "prefs.php_doctor_suggestions_title".localized,
            preference: .showPhpDoctorSuggestions,
            action: {
                MainMenu.shared.refreshIcon()
                MainMenu.shared.rebuild()
            }
        )

    }

    func getNotifyAboutVersionChangePV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.notifications".localized,
            descriptionText: "prefs.notify_about_version_change_desc".localized,
            checkboxText: "prefs.notify_about_version_change".localized,
            preference: .notifyAboutVersionChange,
            action: {}
        )
    }

    func getNotifyAboutPhpFpmChangePV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.notify_about_php_fpm_change_desc".localized,
            checkboxText: "prefs.notify_about_php_fpm_change".localized,
            preference: .notifyAboutPhpFpmRestart,
            action: {}
        )
    }

    func getNotifyAboutServicesPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.notify_about_services_desc".localized,
            checkboxText: "prefs.notify_about_services".localized,
            preference: .notifyAboutServices,
            action: {}
        )
    }

    func getNotifyAboutPresetsPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.notify_about_presets_desc".localized,
            checkboxText: "prefs.notify_about_presets".localized,
            preference: .notifyAboutPresets,
            action: {}
        )
    }

    func getNotifyAboutSecureTogglePV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.notify_about_secure_status_desc".localized,
            checkboxText: "prefs.notify_about_secure_status".localized,
            preference: .notifyAboutSecureToggle,
            action: {}
        )
    }

    func getNotifyAboutGlobalComposerStatusPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.notify_about_composer_success_desc".localized,
            checkboxText: "prefs.notify_about_composer_success".localized,
            preference: .notifyAboutGlobalComposerStatus,
            action: {}
        )
    }

    func getWarnAboutNonStandardTldPV() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.warnings".localized,
            descriptionText: "prefs.warn_about_non_standard_tld_desc".localized,
            checkboxText: "prefs.warn_about_non_standard_tld".localized,
            preference: .warnAboutNonStandardTLD,
            action: {}
        )
    }

    func displayFeature(
        _ localizationKey: String,
        _ preference: PreferenceName,
        _ first: Bool = false
    ) -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: first ? "prefs.menu_contents".localized : "",
            descriptionText: "\(localizationKey)_desc".localized,
            checkboxText: localizationKey.localized,
            preference: preference,
            action: {
                MainMenu.shared.refreshIcon()
                MainMenu.shared.rebuild()
            }
        )
    }

    // MARK: - Listening for hotkey delegate

    var listeningForHotkeyView: HotkeyPreferenceView?

    override func viewWillDisappear() {
        if listeningForHotkeyView !== nil {
            listeningForHotkeyView = nil
        }
    }
}
