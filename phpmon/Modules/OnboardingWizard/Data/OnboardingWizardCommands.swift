//
//  OnboardingWizardCommands.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

extension Toolchain {
    enum Commands {
        static let developerToolsPathLookup = "/usr/bin/xcode-select -p"
        static let developerToolsInstall = "/usr/bin/xcode-select --install"
        static let homebrewInstall = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

        static func phpComposerInstall(using brew: String) -> [String] {
            return [
                "\(brew) tap shivammathur/php",
                "\(brew) tap shivammathur/extensions",
                "\(brew) install php composer"
            ]
        }

        static func valetInstall(using composer: String) -> String {
            return "\(composer) global require laravel/valet"
        }

        static func valetTrust(using valet: String) -> String {
            return "\(valet) trust"
        }

        static func valetConfigure(using valet: String) -> String {
            return "\(valet) install"
        }
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
