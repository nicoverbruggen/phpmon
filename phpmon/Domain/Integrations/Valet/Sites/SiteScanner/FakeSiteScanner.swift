//
//  FakeSiteScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

class FakeSiteScanner: SiteScanner {
    let fakes = [
        ValetSite(fakeWithName: "laravel", tld: "test", secure: true,
                  path: "~/Code/laravel/framework", linked: true),

        ValetSite(fakeWithName: "tailwind", tld: "test", secure: true,
                  path: "~/Code/tailwind/site", linked: true, constraint: "8.0"),

        ValetSite(fakeWithName: "forge", tld: "test", secure: true,
                  path: "~/Code/laravel/forge", linked: true),

        ValetSite(fakeWithName: "concord", tld: "test", secure: false,
                  path: "~/Code/concord", linked: true, driver: "Laravel (^8.0)", constraint: "^7.4", isolated: "7.4"),

        ValetSite(fakeWithName: "drupal", tld: "test", secure: false,
                  path: "~/Sites/drupal", linked: false, driver: "Drupal", constraint: "^7.4", isolated: "7.4"),

        ValetSite(fakeWithName: "wordpress", tld: "test", secure: false,
                  path: "~/Sites/wordpress", linked: false, driver: "WordPress", constraint: "^7.4", isolated: "7.4")
    ]

    func resolveSiteCount(paths: [String]) -> Int {
        return fakes.count
    }

    func resolveSitesFrom(paths: [String]) -> [ValetSite] {
        return fakes
    }

    func resolveSite(path: String) -> ValetSite? {
        return nil
    }
}
