//
//  WarningManagerTrustTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

struct WarningManagerTrustTest {
    @Test func php_doctor_warns_and_fixes_untrusted_taps_when_supported() async {
        let container = Container()
        container.withFakeSystemContext(
            architecture: "arm64",
            configuredShell: "/bin/zsh"
        )
        container.bind(coreOnly: true, commandTracking: false)
        container.overrideFake(
            shellExpectations: [
                "sysctl -n sysctl.proc_translated": .instant("0"),
                "/opt/homebrew/bin/brew tap": .instant("""
                shivammathur/php
                shivammathur/extensions
                """),
                "/opt/homebrew/bin/brew help trust": .instant("Usage: brew trust [options] [target ...]\n"),
                "/opt/homebrew/bin/brew trust --tap": .instant("""
                All official taps and commands are trusted.
                Trusted taps:
                  shivammathur/extensions
                """),
                "/opt/homebrew/bin/brew trust --tap shivammathur/php": BatchFakeShellOutput(
                    items: [.instant("Trusted tap: shivammathur/php\n")],
                    transactions: [
                        .write("", to: "/tmp/phpmon-doctor-trusted-php"),
                        .shell(
                            "/opt/homebrew/bin/brew trust --tap",
                            .instant("""
                            All official taps and commands are trusted.
                            Trusted taps:
                              shivammathur/php
                              shivammathur/extensions
                            """)
                        )
                    ]
                )
            ],
            fileSystemFiles: [
                "/opt/homebrew/bin/brew": .fake(.binary)
            ],
            commandTracking: false
        )

        let manager = WarningManager(container: container)
        await manager.checkEnvironment()

        // The single combined warning fires because `shivammathur/php` is untrusted,
        // even though `shivammathur/extensions` is already trusted.
        let warning = manager.warnings.first {
            $0.name == "Required Homebrew taps are not trusted"
        }
        #expect(warning != nil)

        await warning?.fix?()

        let warningStillExists = manager.warnings.contains {
            $0.name == "Required Homebrew taps are not trusted"
        }

        // The fix trusts only the untrusted tap (`shivammathur/php`); the already-trusted
        // `shivammathur/extensions` is skipped, so its trust command is never run.
        #expect(container.filesystem.fileExists("/tmp/phpmon-doctor-trusted-php"))
        #expect(!warningStillExists)
    }
}
