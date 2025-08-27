//
//  PackagistTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/08/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing

@Suite("Integration")
struct PackagistTest {
    @Test func canRetrieveLaravelValetVersion() async {
        let packageToCheck = "laravel/valet"
        let latestVersion = try? await Packagist.getLatestStableVersion(packageName: packageToCheck)

        #expect(latestVersion != nil)
    }
}
