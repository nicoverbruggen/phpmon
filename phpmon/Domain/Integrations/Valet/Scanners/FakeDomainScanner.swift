//
//  FakeDomainScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

class FakeDomainScanner: DomainScanner {

    var sites: [ValetSite] = [
        FakeValetSite(withDomain: "larament", tld: "test", secure: true,
                      path: "~/Code/sites/larament", linked: true),

        FakeValetSite(withDomain: "symfony", tld: "test", secure: true,
                  path: "~/Code/sites/symfony", linked: true, driver: "Symfony (^7.3)"),

        FakeValetSite(withDomain: "tempest", tld: "test", secure: true,
                  path: "~/Code/sites/tempest", linked: true, driver: "Tempest (^1.6)", constraint: "^8.4"),

        FakeValetSite(withDomain: "drupal", tld: "test", secure: false,
                  path: "~/Sites/drupal", linked: false, driver: "Drupal", constraint: "^8.2", isolated: "8.2"),

        FakeValetSite(withDomain: "wordpress", tld: "test", secure: false,
                  path: "~/Sites/wordpress", linked: false, driver: "WordPress", constraint: "^8.0", isolated: "8.0"),

        FakeValetSite(withDomain: "concord", tld: "test", secure: false,
                  path: "~/Code/concord", linked: true, driver: "Laravel (^10)", constraint: "^8.3", isolated: "8.3"),

        FakeValetSite(withDomain: "gen-ai-mcp", tld: "test", secure: true,
                      path: "~/Code/gen-ai-mcp", linked: true, driver: "Laravel (^12)",
                      constraint: "^8.4", isolated: "8.4")
    ]

    var proxies: [ValetProxy] = [
        FakeValetProxy(withDomain: "mailgun", target: "http://127.0.0.1:9999", secure: true, tld: "test")
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
