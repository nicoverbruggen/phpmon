//
//  OnboardingWizardCommands.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Toolchain {
    enum Commands {
        // 1. Installing Command Line Tools
        static let commandLineToolsStatus = "/usr/bin/xcode-select -p"
        static let commandLineToolsInstall = "/usr/bin/xcode-select --install"

        // 2. Installing Homebrew
        static let homebrewInstall = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

        // 3. PHP & Composer Installation
        static func phpComposerInstall(
            using brew: String
        ) -> [String] {
            return [
                "\(brew) tap shivammathur/php",
                "\(brew) tap shivammathur/extensions",
                "\(brew) install php composer"
            ]
        }

        // 4. Valet Installation
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

        // 5. Valet Trust
        static func valetTrust(
            using valet: String
        ) -> String {
            return "\(valet) trust"
        }

        static let checkSudoersValet = "cat /private/etc/sudoers.d/valet"
        static let checkSudoersBrew = "cat /private/etc/sudoers.d/brew"
    }
}

extension ShellEnvironment {
    func pathInstructionLines() -> [String] {
        return [
            phpMonitorBinPathExport,
            composerBinPathExport,
            homebrewBinPathExport
        ]
    }
}
