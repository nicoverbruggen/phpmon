//
//  PrefsVC.swift
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

    func getIconOptionsPV() -> NSView {
        return SelectPreferenceView.make(
            sectionText: "",
            descriptionText: "prefs.icon_options_desc".localized,
            options: MenuBarIcon.allCases.map({ return $0.rawValue }),
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

    func getAutoRestartPV() -> NSView {
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

    func getWarnAboutNonStandardTLD() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.warnings".localized,
            descriptionText: "prefs.warn_about_non_standard_tld_desc".localized,
            checkboxText: "prefs.warn_about_non_standard_tld".localized,
            preference: .warnAboutNonStandardTLD,
            action: {}
        )
    }

    func getDisplayMenuSectionPV(
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

class GeneralPreferencesVC: GenericPreferenceVC {

    // MARK: - Lifecycle

    public static func fromStoryboard() -> GenericPreferenceVC {
        var vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            vc.getShowPhpDoctorSuggestionsPV(),
            vc.getAutoRestartPV(),
            vc.getAutomaticComposerUpdatePV(),
            vc.getShortcutPV(),
            vc.getIntegrationsPV(),
            vc.getAutomaticUpdateCheckPV()
        ]

        if #available(macOS 13, *) {
            vc.views.append(CheckboxPreferenceView.makeLoginItemView())
        }

        return vc
    }
}

class NotificationPreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            vc.getNotifyAboutVersionChangePV(),
            vc.getNotifyAboutPresetsPV(),
            vc.getNotifyAboutSecureTogglePV(),
            vc.getNotifyAboutGlobalComposerStatusPV(),
            vc.getNotifyAboutServicesPV(),
            vc.getNotifyAboutPhpFpmChangePV(),
            vc.getWarnAboutNonStandardTLD()
        ]

        return vc
    }

}

class MenuStructurePreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            vc.getDisplayMenuSectionPV("prefs.display_global_version_switcher", .displayGlobalVersionSwitcher, true),
            vc.getDisplayMenuSectionPV("prefs.display_services_manager", .displayServicesManager),
            vc.getDisplayMenuSectionPV("prefs.display_valet_integration", .displayValetIntegration),
            vc.getDisplayMenuSectionPV("prefs.display_php_config_finder", .displayPhpConfigFinder),
            vc.getDisplayMenuSectionPV("prefs.display_composer_toolkit", .displayComposerToolkit),
            vc.getDisplayMenuSectionPV("prefs.display_limits_widget", .displayLimitsWidget),
            vc.getDisplayMenuSectionPV("prefs.display_extensions", .displayExtensions),
            vc.getDisplayMenuSectionPV("prefs.display_presets", .displayPresets),
            vc.getDisplayMenuSectionPV("prefs.display_misc", .displayMisc)

        ]

        return vc
    }
}

class AppearancePreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            vc.getDynamicIconPV(),
            vc.getIconOptionsPV(),
            vc.getIconDensityPV()
        ]

        return vc
    }
}
