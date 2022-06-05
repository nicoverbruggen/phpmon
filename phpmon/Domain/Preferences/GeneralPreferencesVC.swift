//
//  GeneralPreferencesVC.swift
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

}

class GeneralPreferencesVC: GenericPreferenceVC {

    // MARK: - Icon and title

    var icon: String = "gear"

    // MARK: - Lifecycle

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        vc.views = [
            getDynamicIconPreferenceView(),
            getIconOptionsPreferenceView(),
            getIconDensityPreferenceView(),
            getAutoRestartPreferenceView(),
            getAutomaticComposerUpdatePreferenceView(),
            // getShortcutPreferenceView(),
            getIntegrationsPreferenceView(),
            getAutomaticUpdateCheckPreferenceView()
        ]

        return vc
    }

    private static func getDynamicIconPreferenceView() -> NSView {
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

    private static func getIconOptionsPreferenceView() -> NSView {
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

    private static func getIconDensityPreferenceView() -> NSView {
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

    private static func getAutoRestartPreferenceView() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.services".localized,
            descriptionText: "prefs.auto_restart_services_desc".localized,
            checkboxText: "prefs.auto_restart_services_title".localized,
            preference: .autoServiceRestartAfterExtensionToggle,
            action: {}
        )
    }

    private static func getAutomaticComposerUpdatePreferenceView() -> NSView {
        CheckboxPreferenceView.make(
            sectionText: "prefs.switcher".localized,
            descriptionText: "prefs.auto_composer_update_desc".localized,
            checkboxText: "prefs.auto_composer_update_title".localized,
            preference: .autoComposerGlobalUpdateAfterSwitch,
            action: {}
        )
    }

    /*
    private static func getShortcutPreferenceView() -> NSView {
        return HotkeyPreferenceView.make(
            sectionText: "prefs.global_shortcut".localized,
            descriptionText: "prefs.shortcut_desc".localized,
            self
        )
    }
    */

    private static func getIntegrationsPreferenceView() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.integrations".localized,
            descriptionText: "prefs.open_protocol_desc".localized,
            checkboxText: "prefs.open_protocol_title".localized,
            preference: .allowProtocolForIntegrations,
            action: {}
        )
    }

    private static func getAutomaticUpdateCheckPreferenceView() -> NSView {
        return CheckboxPreferenceView.make(
            sectionText: "prefs.updates".localized,
            descriptionText: "prefs.automatic_update_check_desc".localized,
            checkboxText: "prefs.automatic_update_check_title".localized,
            preference: .automaticBackgroundUpdateCheck,
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
