//
//  Feature_Tests.swift
//  Feature Tests
//
//  Created by Nico Verbruggen on 14/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import XCTest

final class InternalSwitcherTest: FeatureTestCase {

    public func testDefaultPhpFpmPoolIsMoved() async {
        ActiveFileSystem.useTestable([
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf": .fake(.text)
        ])

        let outcome = await InternalSwitcher().disableDefaultPhpFpmPool("8.1")
        XCTAssertTrue(outcome)

        assertFileSystemHas("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon")
        assertFileSystemDoesNotHave("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf")
    }

    public func testExistingDisabledByPhpMonFileIsRemoved() async {
        ActiveFileSystem.useTestable([
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf": .fake(.text, "system generated"),
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon": .fake(.text, "phpmon generated")
        ])

        assertFileHasContents(
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon",
            contents: "phpmon generated"
        )

        let outcome = await InternalSwitcher().disableDefaultPhpFpmPool("8.1")
        XCTAssertTrue(outcome)

        assertFileSystemHas("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon")
        assertFileSystemDoesNotHave("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf")

        assertFileHasContents(
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon",
            contents: "system generated"
        )
    }

}
