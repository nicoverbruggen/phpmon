//
//  NginxConfigurationTest.swift
//  phpmon-tests
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class NginxConfigurationTest: XCTestCase {

    static var regularUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nginx-site", withExtension: "test")!
    }

    static var isolatedUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nginx-site-isolated", withExtension: "test")!
    }

    static var proxyUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nginx-proxy", withExtension: "test")!
    }

    static var secureProxyUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nginx-secure-proxy", withExtension: "test")!
    }

    func testCanDetermineSiteNameAndTld() throws {
        XCTAssertEqual(
            "nginx-site",
            NginxConfiguration(filePath: NginxConfigurationTest.regularUrl.path).domain
        )
        XCTAssertEqual(
            "test",
            NginxConfiguration(filePath: NginxConfigurationTest.regularUrl.path).tld
        )
    }

    func testCanDetermineIsolation() throws {
        XCTAssertNil(
            NginxConfiguration(filePath: NginxConfigurationTest.regularUrl.path).isolatedVersion
        )

        XCTAssertEqual(
            "8.1",
            NginxConfiguration(filePath: NginxConfigurationTest.isolatedUrl.path).isolatedVersion
        )
    }

    func testCanDetermineProxy() throws {
        let proxied = NginxConfiguration(filePath: NginxConfigurationTest.proxyUrl.path)
        XCTAssertTrue(proxied.contents.contains("# valet stub: proxy.valet.conf"))
        XCTAssertEqual("http://127.0.0.1:90", proxied.proxy)

        let normal = NginxConfiguration(filePath: NginxConfigurationTest.regularUrl.path)
        XCTAssertFalse(normal.contents.contains("# valet stub: proxy.valet.conf"))
        XCTAssertEqual(nil, normal.proxy)
    }

    func testCanDetermineSecuredProxy() throws {
        let proxied = NginxConfiguration(filePath: NginxConfigurationTest.secureProxyUrl.path)
        XCTAssertTrue(proxied.contents.contains("# valet stub: secure.proxy.valet.conf"))
        XCTAssertEqual("http://127.0.0.1:90", proxied.proxy)
    }

}
