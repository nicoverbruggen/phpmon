//
//  NginxConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import XCTest

class NginxConfigurationTest: XCTestCase {

    // MARK: - Test Files

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

    static var customTldProxyUrl: URL {
        return Bundle(for: Self.self).url(forResource: "nginx-secure-proxy-custom-tld", withExtension: "test")!
    }

    // MARK: - Tests

    func test_can_determine_site_name_and_tld() throws {
        XCTAssertEqual(
            "nginx-site",
            NginxConfigurationFile.from(filePath: NginxConfigurationTest.regularUrl.path)?.domain
        )
        XCTAssertEqual(
            "test",
            NginxConfigurationFile.from(filePath: NginxConfigurationTest.regularUrl.path)?.tld
        )
    }

    func test_can_determine_isolation() throws {
        XCTAssertNil(
            NginxConfigurationFile.from(filePath: NginxConfigurationTest.regularUrl.path)?.isolatedVersion
        )

        XCTAssertEqual(
            "8.1",
            NginxConfigurationFile.from(filePath: NginxConfigurationTest.isolatedUrl.path)?.isolatedVersion
        )
    }

    func test_can_determine_proxy() throws {
        let proxied = NginxConfigurationFile.from(filePath: NginxConfigurationTest.proxyUrl.path)!
        XCTAssertTrue(proxied.contents.contains("# valet stub: proxy.valet.conf"))
        XCTAssertEqual("http://127.0.0.1:90", proxied.proxy)

        let normal = NginxConfigurationFile.from(filePath: NginxConfigurationTest.regularUrl.path)!
        XCTAssertFalse(normal.contents.contains("# valet stub: proxy.valet.conf"))
        XCTAssertEqual(nil, normal.proxy)
    }

    func test_can_determine_secured_proxy() throws {
        let proxied = NginxConfigurationFile.from(filePath: NginxConfigurationTest.secureProxyUrl.path)!
        XCTAssertTrue(proxied.contents.contains("# valet stub: secure.proxy.valet.conf"))
        XCTAssertEqual("http://127.0.0.1:90", proxied.proxy)
    }

    func test_can_determine_proxy_with_custom_tld() throws {
        let proxied = NginxConfigurationFile.from(filePath: NginxConfigurationTest.customTldProxyUrl.path)!
        XCTAssertTrue(proxied.contents.contains("# valet stub: secure.proxy.valet.conf"))
        XCTAssertEqual("http://localhost:8080", proxied.proxy)
    }

}
