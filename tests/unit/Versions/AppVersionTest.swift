//
//  AppVersionTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 10/05/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

struct AppVersionTest {
    @Test func test_can_parse_normal_version_string() {
        let version = AppVersion.from("1.0.0")

        #expect(version != nil)
        #expect(version!.version == "1.0.0")
        #expect(version!.build == nil)
        #expect(version!.suffix == nil)
    }

    @Test func test_can_parse_cask_version_string() {
        let version = AppVersion.from("1.0.0_600")

        #expect(version != nil)
        #expect(version!.version == "1.0.0")
        #expect(version!.build == 600)
        #expect(version!.suffix == nil)
    }

    @Test func test_can_parse_dev_version_string_without_build_number() {
        let version = AppVersion.from("1.0.0-dev")

        #expect(version != nil)
        #expect(version!.version == "1.0.0")
        #expect(version!.build == nil)
        #expect(version!.suffix == "dev")
    }

    @Test func test_can_parse_dev_version_string_with_build_number() {
        let version = AppVersion.from("1.0.0-dev,870")

        #expect(version != nil)
        #expect(version!.version == "1.0.0")
        #expect(version!.build == 870)
        #expect(version!.suffix == "dev")
    }

    @Test func test_can_parse_underscores_as_build_separator() {
        let version = AppVersion.from("1.0.0-dev_870")

        #expect(version != nil)
        #expect(version!.version == "1.0.0")
        #expect(version!.build == 870)
        #expect(version!.suffix == "dev")
    }

    @Test func test_can_compare_version_numbers() {
        // Build is newer
        #expect(AppVersion.from("5.0_101")! > AppVersion.from("5.0_100")!)

        // Version and build is the same
        #expect(AppVersion.from("5.0.0_100")! == AppVersion.from("5.0_100")!)

        // Version is newer
        #expect(AppVersion.from("5.1_100")! > AppVersion.from("5.0_100")!)

        // Build is older
        #expect(AppVersion.from("5.0_101")! < AppVersion.from("5.0_102")!)
    }
}
