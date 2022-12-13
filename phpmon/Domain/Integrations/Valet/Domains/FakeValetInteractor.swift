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
        if let scanner = ValetScanners.siteScanner as? FakeSiteScanner {
            scanner.fakes.removeAll { $0 === site }
        }
    }

    override func remove(proxy: ValetProxy) async throws {
        await delay(seconds: delayTime)
        #warning("A fake proxy scanner needs to be added")
    }
}
