//
//  CommandCatalog.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

enum CommandCatalog {
    enum Toolchain {
        static let commandLineToolsStatus = "/usr/bin/xcode-select -p"
    }

    enum Onboarding {
        static let commandLineToolsInstall = "/usr/bin/xcode-select --install"
        static let homebrewInstall = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#
        static let checkSudoersValet = "cat /private/etc/sudoers.d/valet"
        static let checkSudoersBrew = "cat /private/etc/sudoers.d/brew"
        static let valetSudoersPath = "/etc/sudoers.d/phpmon-valet-onboarding"
        static let valetSudoersTemp = "/tmp/phpmon-valet-onboarding.sudoers"
        static let valetSudoersCleanupCommand = "sudo rm -f \(valetSudoersPath) \(valetSudoersTemp)"

        static func phpComposerInstall(using brew: String) -> String {
            // The required taps (and their trust commands) are added by the caller,
            // so this only covers the install step.
            return "\(brew) install php composer"
        }

        static func valetInstall(
            using brew: String,
            composer: String,
            valet: String
        ) -> [String] {
            return [
                "\(composer) global require laravel/valet",
                "\(brew) install dnsmasq nginx",
                "\(valet) install"
            ]
        }

        static func valetTrust(using valet: String) -> String {
            return "\(valet) trust"
        }

        static func makeValetSudoersInstallScript(forScriptAt valetPath: String) -> String {
            let entry = "Cmnd_Alias VALET_PHPMON = \(valetPath) install, \(valetPath) trust"
            let perm = "%admin ALL=(root) NOPASSWD:SETENV: VALET_PHPMON"

            return [
                "rm -f \(valetSudoersTemp)",
                "echo '\(entry)' > \(valetSudoersTemp)",
                "echo '\(perm)' >> \(valetSudoersTemp)",
                "/usr/sbin/visudo -cf \(valetSudoersTemp)",
                "chmod 0440 \(valetSudoersTemp)",
                "chown root:wheel \(valetSudoersTemp)",
                "mv \(valetSudoersTemp) \(valetSudoersPath)"
            ].joined(separator: " && ")
        }
    }
}
