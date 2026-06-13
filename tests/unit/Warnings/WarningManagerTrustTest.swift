//
//  WarningManagerTrustTest.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 09/06/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Testing

@Suite(.serialized)
struct WarningManagerTrustTest {
    private func makeWarningManager(
        shellExpectations: [String: BatchFakeShellOutput],
        fileSystemFiles: [String: FakeFile] = [
            "/opt/homebrew/bin/brew": .fake(.binary)
        ]
    ) -> WarningManager {
        let container = Container()
        container.withFakeSystemContext(
            architecture: "arm64",
            configuredShell: "/bin/zsh"
        )
        container.bind(coreOnly: false, commandTracking: false)
        container.overrideFake(
            shellExpectations: shellExpectations,
            fileSystemFiles: fileSystemFiles,
            commandTracking: false
        )

        PhpConfigChecker.shared = PhpConfigChecker(container)
        App.shared.container = container
        Valet.shared.container = container
        Valet.shared.installed = false

        return WarningManager(container: container)
    }

    private func warning(named name: String, in manager: WarningManager) -> Warning {
        return manager.allAvailableWarnings().first {
            $0.name == name
        }!
    }

    @Test func all_warning_definitions_are_accounted_for() {
        let manager = makeWarningManager(shellExpectations: [:])
        let names = manager.allAvailableWarnings().map(\.name)

        #expect(names == [
            "Running PHP Monitor with Rosetta on Apple Silicon",
            "Helpers cannot be symlinked and not in PATH",
            "Configured shell path is invalid",
            "Missing configuration file for `xdebug.mode`",
            "Required Homebrew taps are missing",
            "Required Homebrew taps are not trusted",
            "Your PHP installation is missing configuration files",
            "One or more domain certificates expired"
        ])
    }

    @Test func all_warning_evaluations_can_run_in_quiet_environment() async {
        let manager = makeWarningManager(shellExpectations: [
            "sysctl -n sysctl.proc_translated": .instant("0"),
            "/opt/homebrew/bin/brew tap": .instant("""
            shivammathur/php
            shivammathur/extensions
            """),
            "/opt/homebrew/bin/brew help trust": .instant("Usage: brew trust [options] [target ...]\n"),
            "/opt/homebrew/bin/brew trust --tap": .instant("""
            All official taps and commands are trusted.
            Trusted taps:
              shivammathur/php
              shivammathur/extensions
            """)
        ])

        if let shell = manager.container.shell as? TestableShell {
            shell.PATH = [
                "/usr/local/bin",
                "/usr/bin",
                "/bin",
                "/usr/sbin",
                "\(manager.container.paths.homePath)/.config/phpmon/bin",
                manager.container.paths.binPath
            ].joined(separator: ":")
        }

        await manager.checkEnvironment()

        #expect(manager.warnings.isEmpty)
    }

    @Test func php_doctor_warns_and_fixes_untrusted_taps_when_supported() async {
        let manager = makeWarningManager(shellExpectations: [
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
        ])

        await manager.brewDiagnostics.loadInstalledTaps()
        await manager.brewDiagnostics.loadTrustedTaps()

        // The combined warning fires because `shivammathur/php` is untrusted,
        // even though `shivammathur/extensions` is already trusted.
        let warning = warning(named: "Required Homebrew taps are not trusted", in: manager)
        #expect(await warning.applies())

        await warning.fix?()

        let warningStillExists = manager.warnings.contains {
            $0.name == "Required Homebrew taps are not trusted"
        }

        // The fix trusts only the untrusted tap (`shivammathur/php`); the already-trusted
        // `shivammathur/extensions` is skipped, so its trust command is never run.
        #expect(manager.container.filesystem.fileExists("/tmp/phpmon-doctor-trusted-php"))
        #expect(!warningStillExists)
    }

    @Test func php_doctor_does_not_warn_about_untrusted_taps_when_extensions_tap_is_missing() async {
        let manager = makeWarningManager(shellExpectations: [
            "/opt/homebrew/bin/brew tap": .instant("""
            shivammathur/php
            """),
            "/opt/homebrew/bin/brew help trust": .instant("Usage: brew trust [options] [target ...]\n"),
            "/opt/homebrew/bin/brew trust --tap": .instant("""
            All official taps and commands are trusted.
            No trusted taps, formulae, casks or commands.
            """)
        ])

        await manager.brewDiagnostics.loadInstalledTaps()
        await manager.brewDiagnostics.loadTrustedTaps()

        let missingWarning = warning(named: "Required Homebrew taps are missing", in: manager)
        let untrustedWarning = warning(named: "Required Homebrew taps are not trusted", in: manager)

        #expect(await missingWarning.applies())
        #expect(await !untrustedWarning.applies())
    }
}
