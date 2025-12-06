//
//  App+DetectApps.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/11/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

extension App {
    /**
     Detect which applications are installed that can be used to open a domain's source directory.
     */
    public func detectApplications() async {
        Log.info("Detecting applications...")

        // Start by detecting the default applications
        var detected = await Application.detectPresetApplications(container)

        // Next up, scan for additional apps
        let customApps = Preferences.custom.scanApps?.map { appName in
            return Application(container, appName, .user_supplied)
        } ?? []

        // Append any detected apps
        for app in customApps where await app.isInstalled() {
            detected.append(app)
        }

        App.shared.detectedApplications = detected
        Log.info("Detected applications: \(detected.map { $0.name })")
    }
}
