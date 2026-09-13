//
//  InternalSwitcherTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing
import Foundation

/// In-process integration coverage for `InternalSwitcher`'s PHP-FPM pool handling.
/// (Migrated from the retired "Feature Tests" target so it stays fast, parallel, and
/// runnable under ThreadSanitizer.)
struct InternalSwitcherTest {
    private let poolPath = "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf"
    private var disabledPath: String { "\(poolPath).disabled-by-phpmon" }

    @Test func default_php_fpm_pool_is_moved() async {
        let container = Container.fake(files: [
            poolPath: .fake(.text)
        ])
        let fs = container.filesystem as! TestableFileSystem

        let outcome = await InternalSwitcher(container).disableDefaultPhpFpmPool("8.1")
        #expect(outcome)

        #expect(fs.files.keys.contains(disabledPath))
        #expect(!fs.files.keys.contains(poolPath))
    }

    @Test func existing_disabled_by_phpmon_file_is_removed() async {
        let container = Container.fake(files: [
            poolPath: .fake(.text, "system generated"),
            disabledPath: .fake(.text, "phpmon generated")
        ])
        let fs = container.filesystem as! TestableFileSystem

        #expect(fs.files[disabledPath]?.content == "phpmon generated")

        let outcome = await InternalSwitcher(container).disableDefaultPhpFpmPool("8.1")
        #expect(outcome)

        #expect(fs.files.keys.contains(disabledPath))
        #expect(!fs.files.keys.contains(poolPath))
        // The pre-existing "phpmon generated" file was replaced by the real pool contents.
        #expect(fs.files[disabledPath]?.content == "system generated")
    }
}
