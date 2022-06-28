//
//  PrefsVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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
        Log.perf("PrefsVC deallocated")
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
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            vc.getAutoRestartPV(),
            vc.getAutomaticComposerUpdatePV(),
            vc.getShortcutPV(),
            vc.getIntegrationsPV(),
            vc.getAutomaticUpdateCheckPV()
        ]

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
            vc.getNotifyAboutPhpFpmChangePV()
        ]

        return vc
    }

}

class AppearancePreferencesVC: GenericPreferenceVC {

    // MARK: - Lifecycle

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
