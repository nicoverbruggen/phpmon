//
//  FakeValetInteractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/12/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeValetInteractor: ValetInteractor {
    var delayTime: TimeInterval = 1.0

    override func toggleSecure(proxy: ValetProxy) async throws {
        await delay(seconds: delayTime)
        proxy.secured = !proxy.secured
    }

    override func toggleSecure(site: ValetSite) async throws {
        await delay(seconds: delayTime)
        site.secured = !site.secured
    }

    override func unlink(site: ValetSite) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.sites.removeAll { $0 === site }
        }
    }

    override func isolate(site: ValetSite, version: String) async throws {
        await delay(seconds: delayTime)

        site.isolatedPhpVersion = PhpEnv.shared.cachedPhpInstallations[version]
        site.evaluateCompatibility()
    }

    override func unisolate(site: ValetSite) async throws {
        await delay(seconds: delayTime)

        site.isolatedPhpVersion = nil
        site.evaluateCompatibility()
    }

    override func remove(proxy: ValetProxy) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.proxies.removeAll { $0 === proxy }
        }
    }
}
