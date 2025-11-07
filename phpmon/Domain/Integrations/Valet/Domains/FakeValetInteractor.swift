//
//  FakeValetInteractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 13/12/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class FakeValetInteractor: ValetInteractor {
    var delayTime: TimeInterval = 1.0

    // MARK: - Managing Domains

    override func link(path: String, domain: String) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.sites.append(
                FakeValetSite(
                    fakeWithName: domain,
                    tld: Valet.shared.config.tld,
                    secure: false,
                    path: path,
                    linked: true
                )
            )
        }
    }

    override func unlink(site: ValetSite) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.sites.removeAll { $0 === site }
        }
    }

    override func proxy(domain: String, proxy: String, secure: Bool) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.proxies.append(
                FakeValetProxy(
                    container,
                    domain: domain,
                    target: proxy,
                    secure: secure,
                    tld: Valet.shared.config.tld
                )
            )
        }
    }

    override func remove(proxy: ValetProxy) async throws {
        await delay(seconds: delayTime)

        if let scanner = ValetScanner.active as? FakeDomainScanner {
            scanner.proxies.removeAll { $0.domain == proxy.domain }
        }
    }

    // MARK: - Modifying Domains

    override func toggleSecure(proxy: ValetProxy) async throws {
        await delay(seconds: delayTime)
        proxy.secured = !proxy.secured
    }

    override func toggleSecure(site: ValetSite) async throws {
        await delay(seconds: delayTime)
        site.secured = !site.secured
    }

    override func isolate(site: ValetSite, version: String) async throws {
        await delay(seconds: delayTime)

        site.isolatedPhpVersion = App.shared.container.phpEnvs.cachedPhpInstallations[version]
        site.evaluateCompatibility()
    }

    override func unisolate(site: ValetSite) async throws {
        await delay(seconds: delayTime)

        site.isolatedPhpVersion = nil
        site.evaluateCompatibility()
    }
}
