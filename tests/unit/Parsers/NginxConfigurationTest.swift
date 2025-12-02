//
//  NginxConfigurationTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct NginxConfigurationTest {
    var container: Container

    init () async throws {
        container = Container.real(minimal: true)
    }

    // MARK: - Test Files

    static var regularUrl: URL {
        TestBundle.url(forResource: "nginx-site", withExtension: "test")!
    }

    static var isolatedUrl: URL {
        TestBundle.url(forResource: "nginx-site-isolated", withExtension: "test")!
    }

    static var proxyUrl: URL {
        TestBundle.url(forResource: "nginx-proxy", withExtension: "test")!
    }

    static var secureProxyUrl: URL {
        TestBundle.url(forResource: "nginx-secure-proxy", withExtension: "test")!
    }

    static var customTldProxyUrl: URL {
        TestBundle.url(forResource: "nginx-secure-proxy-custom-tld", withExtension: "test")!
    }

    // MARK: - Tests

    @Test func can_determine_site_name_and_tld() throws {
        #expect("nginx-site" == NginxConfigurationFile.from(container, filePath: Self.regularUrl.path)?.domain)
        #expect("test" == NginxConfigurationFile.from(container, filePath: Self.regularUrl.path)?.tld)
    }

    @Test func can_determine_isolation() throws {
        #expect(nil == NginxConfigurationFile.from(container, filePath: Self.regularUrl.path)?.isolatedVersion)
        #expect("8.1" == NginxConfigurationFile.from(container, filePath: Self.isolatedUrl.path)?.isolatedVersion)
    }

    @Test func can_determine_proxy() throws {
        let proxied = NginxConfigurationFile.from(container, filePath: Self.proxyUrl.path)!
        #expect(proxied.contents.contains("# valet stub: proxy.valet.conf"))
        #expect("http://127.0.0.1:90" == proxied.proxy)

        let normal = NginxConfigurationFile.from(container, filePath: Self.regularUrl.path)!
        #expect(false == normal.contents.contains("# valet stub: proxy.valet.conf"))
        #expect(nil == normal.proxy)
    }

    @Test func can_determine_secured_proxy() throws {
        let proxied = NginxConfigurationFile.from(container, filePath: Self.secureProxyUrl.path)!
        #expect(proxied.contents.contains("# valet stub: secure.proxy.valet.conf"))
        #expect("http://127.0.0.1:90" == proxied.proxy)
    }

    @Test func can_determine_proxy_with_custom_tld() throws {
        let proxied = NginxConfigurationFile.from(container, filePath: Self.customTldProxyUrl.path)!
        #expect(proxied.contents.contains("# valet stub: secure.proxy.valet.conf"))
        #expect("http://localhost:8080" == proxied.proxy)
    }

}
