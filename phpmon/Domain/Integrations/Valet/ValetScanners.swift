//
//  Valet+Scanners.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetScanners {

    static var siteScanner: SiteScanner = ValetSiteScanner()
    static var proxyScanner: ProxyScanner = ValetProxyScanner()

    public static func useFake() {
        ValetScanners.siteScanner = FakeSiteScanner()
        ValetScanners.proxyScanner = EmptyProxyScanner()
    }

}
