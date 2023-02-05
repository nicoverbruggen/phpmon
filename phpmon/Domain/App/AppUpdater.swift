//
//  AppUpdater.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class AppUpdater {

    var caskFile: CaskFile?

    public func checkForUpdates(background: Bool) {
        guard let caskFile = CaskFile.from(
            url: App.version.contains("-dev")
            ? Constants.Urls.DevBuildCaskFile
            : Constants.Urls.StableBuildCaskFile
        ) else {
            return presentCouldNotRetrieveUpdate()
        }

        self.caskFile = caskFile

        if newerVersionExists() {
            presentNewerVersionAvailableAlert()
        } else {
            if !background {
                presentNoNewerVersionAvailableAlert()
            }
        }
    }

    public func newerVersionExists() -> Bool {
        // Do the comparison w/ current version
        return true
    }

    public func presentNewerVersionAvailableAlert() {

    }

    public func presentNoNewerVersionAvailableAlert() {

    }

    public func presentCouldNotRetrieveUpdate() {

    }

    private func prepareForDownload() {

    }
}
