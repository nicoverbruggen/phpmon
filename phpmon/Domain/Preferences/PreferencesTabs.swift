//
//  PreferencesTabs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class GeneralPreferencesVC: GenericPreferenceVC {

    // MARK: - Lifecycle

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        return vc
            .addView(when: true, vc.getLanguageOptionsPV())
            .addView(when: true, vc.getShowPhpDoctorSuggestionsPV())
            .addView(when: true, vc.getAutoRestartServicesPV())
            .addView(when: true, vc.getAutomaticComposerUpdatePV())
            .addView(when: true, vc.getShortcutPV())
            .addView(when: true, vc.getIntegrationsPV())
            .addView(when: true, vc.getAutomaticUpdateCheckPV())
            .addView(when: true, CheckboxPreferenceView.makeLoginItemView())
    }
}

class AppearancePreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        _ = vc.addView(when: true, vc.getDynamicIconPV())
            .addView(when: true, vc.getIconOptionsPV())
            .addView(when: true, vc.getIconDensityPV())

        return vc
    }
}

class MenuStructurePreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        return vc
            .addView(when: true, vc.displayFeature("prefs.display_global_version_switcher", .displayGlobalVersionSwitcher, true))
            .addView(when: Valet.installed, vc.displayFeature("prefs.display_services_manager", .displayServicesManager))
            .addView(when: Valet.installed, vc.displayFeature("prefs.display_valet_integration", .displayValetIntegration))
            .addView(when: true, vc.displayFeature("prefs.display_php_config_finder", .displayPhpConfigFinder))
            .addView(when: true, vc.displayFeature("prefs.display_composer_toolkit", .displayComposerToolkit))
            .addView(when: true, vc.displayFeature("prefs.display_limits_widget", .displayLimitsWidget))
            .addView(when: true, vc.displayFeature("prefs.display_extensions", .displayExtensions))
            .addView(when: true, vc.displayFeature("prefs.display_presets", .displayPresets))
            .addView(when: true, vc.displayFeature("prefs.display_misc", .displayMisc))
            .addView(when: true, vc.displayFeature("prefs.display_driver", .displayDriver))
    }
}

class NotificationPreferencesVC: GenericPreferenceVC {

    public static func fromStoryboard() -> GenericPreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! GenericPreferenceVC

        return vc.addView(when: true, vc.getNotifyAboutVersionChangePV())
            .addView(when: true, vc.getNotifyAboutPresetsPV())
            .addView(when: Valet.installed, vc.getNotifyAboutSecureTogglePV())
            .addView(when: true, vc.getNotifyAboutGlobalComposerStatusPV())
            .addView(when: true, vc.getNotifyAboutServicesPV())
            .addView(when: Valet.installed, vc.getNotifyAboutPhpFpmChangePV())
            .addView(when: Valet.installed, vc.getWarnAboutNonStandardTldPV())
    }

}
