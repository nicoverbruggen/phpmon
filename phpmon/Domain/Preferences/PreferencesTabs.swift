//
//  PreferencesTabs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2023.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import Cocoa

class GeneralPreferencesVC: PreferenceVC {

    // MARK: - Lifecycle

    public static func fromStoryboard() -> PreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! PreferenceVC

        return vc
            .addView(when: always, vc.getLanguageOptionsPV())
            .addView(when: always, vc.getShowPhpDoctorSuggestionsPV())
            .addView(when: always, vc.getAutoRestartServicesPV())
            .addView(when: always, vc.getAutomaticComposerUpdatePV())
            .addView(when: always, vc.getShortcutPV())
            .addView(when: always, vc.getIntegrationsPV())
            .addView(when: always, vc.getAutomaticUpdateCheckPV())
            .addView(when: always, CheckboxPreferenceView.makeLoginItemView())
    }
}

class AppearancePreferencesVC: PreferenceVC {

    public static func fromStoryboard() -> PreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! PreferenceVC

        vc.addView(when: always, vc.getDynamicIconPV())
            .addView(when: always, vc.getIconOptionsPV())
            .addView(when: always, vc.getIconDensityPV())
            .addView(when: App.enabled(feature: .automaticServiceDiscovery),
                     vc.getHideAutoDetectedServicesPV())
            .addView(when: always, vc.getHideMenuIconsPV())

        return vc
    }
}

class MenuStructurePreferencesVC: PreferenceVC {

    public static func fromStoryboard() -> PreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! PreferenceVC

        return vc
            .addView(when: always, vc.displayFeature("prefs.display_global_version_switcher", .displayGlobalVersionSwitcher, true))
            .addView(when: Valet.installed, vc.displayFeature("prefs.display_services_manager", .displayServicesManager))
            .addView(when: Valet.installed, vc.displayFeature("prefs.display_valet_integration", .displayValetIntegration))
            .addView(when: always, vc.displayFeature("prefs.display_php_config_finder", .displayPhpConfigFinder))
            .addView(when: always, vc.displayFeature("prefs.display_composer_toolkit", .displayComposerToolkit))
            .addView(when: always, vc.displayFeature("prefs.display_limits_widget", .displayLimitsWidget))
            .addView(when: always, vc.displayFeature("prefs.display_extensions", .displayExtensions))
            .addView(when: always, vc.displayFeature("prefs.display_presets", .displayPresets))
            .addView(when: always, vc.displayFeature("prefs.display_misc", .displayMisc))
            .addView(when: always, vc.displayFeature("prefs.display_driver", .displayDriver))
    }
}

class NotificationPreferencesVC: PreferenceVC {

    public static func fromStoryboard() -> PreferenceVC {
        let vc = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "preferencesTemplateVC") as! PreferenceVC

        return vc.addView(when: always, vc.getNotifyAboutVersionChangePV())
            .addView(when: always, vc.getNotifyAboutPresetsPV())
            .addView(when: Valet.installed, vc.getNotifyAboutSecureTogglePV())
            .addView(when: always, vc.getNotifyAboutGlobalComposerStatusPV())
            .addView(when: always, vc.getNotifyAboutServicesPV())
            .addView(when: Valet.installed, vc.getNotifyAboutPhpFpmChangePV())
            .addView(when: Valet.installed, vc.getWarnAboutNonStandardTldPV())
    }

}
