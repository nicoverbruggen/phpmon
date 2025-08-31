//
//  ValetUpgrader.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 27/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation
import NVAlert

class ValetUpgrader {
    private static func getGlobalComposerJson() -> ComposerJson? {
        let path = "~/.composer/composer.json".replacingTildeWithHomeDirectory

        do {
            if FileSystem.fileExists(path) {
                return try JSONDecoder().decode(
                    ComposerJson.self,
                    from: String(
                        contentsOf: URL(fileURLWithPath: path),
                        encoding: .utf8
                    ).data(using: .utf8)!
                )
            } else {
                Log.err("The global Composer file is missing. This should, uh, not happen!")
                return nil
            }
        } catch {
            Log.err("Something went wrong reading the Composer JSON file.")
            return nil
        }
    }

    public static func showUpgradeAlert() {
        var valetConstraint: String = "unknown"
        var constraintCheckPassed: Bool?

        if let json = getGlobalComposerJson(), let dependencies = json.dependencies {
            if dependencies.keys.contains("laravel/valet") {
                valetConstraint = dependencies["laravel/valet"]!
            }
        }

        guard let latest = Valet.shared.latestVersion else {
            return Log.err("The latest version is unknown. This should, uh, not happen!")
        }

        if valetConstraint != "unknown" {
            // Do a constraint check
            constraintCheckPassed = !PhpVersionNumberCollection(versions: [latest])
                .matching(constraint: valetConstraint).isEmpty
        }

        Task { @MainActor in
            notifyAboutUpgrade(
                latest: latest.text,
                constraint: valetConstraint,
                passing: constraintCheckPassed ?? false
            )
        }
    }

    @MainActor private static func upgradeValet() {
        ComposerWindow().updateGlobalDependencies(
            notify: true,
            completion: { success in
                if success {
                    notifyAboutCompletion()
                }
            }
        )
    }

    @MainActor private static func notifyAboutCompletion() {
        return NVAlert().withInformation(
            title: "valet_upgraded.title".localized,
            subtitle: "valet_upgraded.subtitle".localized,
            description: "valet_upgraded.description".localized,
        )
        .withPrimary(text: "generic.ok".localized, action: { vc in
            vc.close(with: .OK)
        })
        .show()
    }

    @MainActor private static func notifyAboutUpgrade(latest: String, constraint: String, passing: Bool) {
        let alert = NVAlert().withInformation(
            title: "valet_upgrade_available.title".localized,
            subtitle: "valet_upgrade_available.subtitle".localized(latest),
            description: passing
                ? "valet_upgrade_available.description_constraint_ok".localized(latest)
                : "valet_upgrade_available.description_constraint_fail".localized(constraint, latest)
        )
        .withPrimary(text: "valet_upgrade_available.upgrade".localized, action: { vc in
            vc.close(with: .OK)
            ValetUpgrader.upgradeValet()
        })
        .withSecondary(text: "valet_upgrade_available.cancel".localized)

        if !passing {
            _ = alert.withTertiary(text: "valet_upgrade_available.open_composer".localized, action: { _ in
                MainMenu.shared.openGlobalComposerFolder()
            })
        }

        alert.show()
    }
}
