//
//  Startup+ValetOnboarding.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Startup {
    func refreshAfterInstallingValetViaOnboarding() async {
        container.paths.detectBinaryPaths()

        Valet.shared.installed = true
        Valet.shared.version = nil
        Valet.shared.features = []

        await Valet.shared.updateVersionNumber()

        if Valet.shared.version != nil {
            Valet.shared.validateVersion()
        }

        await Valet.shared.startPreloadingSites()
        await BrewDiagnostics.shared.checkForValetMisconfiguration()
        await Valet.shared.notifyAboutBrokenPhpFpm()
        Valet.shared.notifyAboutUnsupportedTLD()
        await ServicesManager.shared.reloadServicesStatus()

        await MainActor.run {
            AppDelegate.instance.configureMenuItems(standalone: false)
            MainMenu.shared.rebuildImmediately()
        }

        await MainActor.run {
            container.warningManager.evaluateWarnings()
        }
    }
}
