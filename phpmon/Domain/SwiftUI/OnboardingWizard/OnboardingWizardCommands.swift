//
//  OnboardingWizardCommands.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

enum OnboardingWizardCommands {
    static let developerToolsInstall = "/usr/bin/xcode-select --install"

    static let homebrewInstall = #"NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    static let phpComposerInstall = "brew install php composer"

    static func pathInstructionLines(in container: Container) -> [String] {
        return [
            ZshRunCommand.composerPathLine(),
            ZshRunCommand.homebrewPathLine(in: container)
        ]
    }
}
