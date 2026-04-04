//
//  ValetConfigParserTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct ValetConfigurationTest {
    static var jsonConfigFileUrl: URL {
        TestBundle.url(forResource: "valet-config", withExtension: "json")!
    }

    @Test func can_load_config_file() throws {
        let json = try? String(
            contentsOf: Self.jsonConfigFileUrl,
            encoding: .utf8
        )
        let config = try! JSONDecoder().decode(
            Valet.Configuration.self,
            from: json!.data(using: .utf8)!
        )

        #expect(config.tld == "test")
        #expect(config.paths == [
            "/Users/username/.config/valet/Sites",
            "/Users/username/Sites"
        ])
        #expect(config.defaultSite == "/Users/username/default-site")
        #expect(config.loopback == "127.0.0.1")
    }
}
