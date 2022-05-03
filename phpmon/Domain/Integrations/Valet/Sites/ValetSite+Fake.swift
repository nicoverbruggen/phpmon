//
//  ValetSite+Fake.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension ValetSite {

    convenience init(
        fakeWithName name: String,
        tld: String,
        secure: Bool,
        path: String,
        linked: Bool,
        driver: String = "Laravel (^9.0)",
        constraint: String = "^8.1",
        isolated: String? = nil
    ) {
        self.init(name: name, tld: tld, absolutePath: path, aliasPath: nil, makeDeterminations: false)
        self.secured = secure
        self.composerPhp = constraint

        self.composerPhpCompatibleWithLinked = self.composerPhp.split(separator: "|")
            .map { string in
                return !PhpVersionNumberCollection.make(from: [PhpEnv.phpInstall.version.long])
                    .matching(constraint: string.trimmingCharacters(in: .whitespacesAndNewlines))
                    .isEmpty
            }.contains(true)

        self.driver = driver
        self.driverDeterminedByComposer = true
        if linked {
            self.aliasPath = self.absolutePath
        }
        if let isolated = isolated {
            self.isolatedPhpVersion = PhpInstallation(isolated)
        }
    }

}
