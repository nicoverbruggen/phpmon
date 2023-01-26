//
//  FakeDomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

class FakeDomainScanner: DomainScanner {

    var sites: [ValetSite] = [
        FakeValetSite(fakeWithName: "laravel", tld: "test", secure: true,
                  path: "~/Code/laravel/framework", linked: true),

        FakeValetSite(fakeWithName: "tailwind", tld: "test", secure: true,
                  path: "~/Code/tailwind/site", linked: true, constraint: "8.0"),

        FakeValetSite(fakeWithName: "forge", tld: "test", secure: true,
                  path: "~/Code/laravel/forge", linked: true),

        FakeValetSite(fakeWithName: "concord", tld: "test", secure: false,
                  path: "~/Code/concord", linked: true, driver: "Laravel (^8.0)", constraint: "^7.4", isolated: "7.4"),

        FakeValetSite(fakeWithName: "drupal", tld: "test", secure: false,
                  path: "~/Sites/drupal", linked: false, driver: "Drupal", constraint: "^7.4", isolated: "7.4"),

        FakeValetSite(fakeWithName: "wordpress", tld: "test", secure: false,
                  path: "~/Sites/wordpress", linked: false, driver: "WordPress", constraint: "^7.4", isolated: "7.4")
    ]

    var proxies: [ValetProxy] = [
        FakeValetProxy(domain: "mailgun", target: "http://127.0.0.1:9999", secure: true, tld: "test")
    ]

    // MARK: - Sites

    func resolveSiteCount(paths: [String]) -> Int {
        return sites.count
    }

    func resolveSitesFrom(paths: [String]) -> [ValetSite] {
        return sites
    }

    func resolveSite(path: String) -> ValetSite? {
        return nil
    }

    // MARK: - Proxies

    func resolveProxies(directoryPath: String) -> [ValetProxy] {
        return proxies
    }
}
