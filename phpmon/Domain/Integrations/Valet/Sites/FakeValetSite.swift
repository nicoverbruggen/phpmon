//
//  ValetSite+Fake.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeValetSite: ValetSite {
    convenience init(
        fakeWithName name: String,
        tld: String,
        secure: Bool,
        path: String,
        linked: Bool,
        driver: String = "Laravel (^12)",
        constraint: String = "^8.4",
        isolated: String? = nil
    ) {
        self.init(
            App.shared.container,
            name: name,
            tld: tld,
            absolutePath: path,
            aliasPath: nil,
            makeDeterminations: false
        )

        self.secured = secure
        self.preferredPhpVersion = constraint
        self.preferredPhpVersionSource = constraint != "" ? .require : .unknown

        self.driver = driver
        self.driverDeterminedByComposer = true

        if linked {
            self.aliasPath = self.absolutePath
        }

        if let isolated = isolated {
            self.isolatedPhpVersion = PhpInstallation(container, isolated)
        }

        if container.phpEnvs.currentInstall != nil {
            self.evaluateCompatibility()
        }
    }
}
