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
        let c = Container.fake(files: [
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf": .fake(.text)
        ]), fs = c.filesystem as! TestableFileSystem

        let outcome = await InternalSwitcher(c)
            .disableDefaultPhpFpmPool("8.1")

        XCTAssertTrue(outcome)

        assertFileSystemHas("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon", in: fs)
        assertFileSystemDoesNotHave("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf", in: fs)
    }

    public func testExistingDisabledByPhpMonFileIsRemoved() async {
        let container = Container.fake(files: [
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf": .fake(.text, "system generated"),
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon": .fake(.text, "phpmon generated")
        ]), fs = container.filesystem as! TestableFileSystem

        assertFileHasContents("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon",
            contents: "phpmon generated", in: fs)

        let outcome = await InternalSwitcher(container).disableDefaultPhpFpmPool("8.1")
        XCTAssertTrue(outcome)

        assertFileSystemHas("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon", in: fs)
        assertFileSystemDoesNotHave("/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf", in: fs)

        assertFileHasContents(
            "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf.disabled-by-phpmon",
            contents: "system generated", in: fs
        )
    }

}
