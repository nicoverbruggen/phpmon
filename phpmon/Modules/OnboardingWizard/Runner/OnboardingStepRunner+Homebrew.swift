//
//  OnboardingStepRunner+Homebrew.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 26/05/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit
import Foundation

extension OnboardingStepRunner {
    var isSimulatingShellEnvironment: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }
    /**
     Request Homebrew to be installed. This is not automatic.
     To make this easy for the user, the install command is copied to the pasteboard.

     The user then has to copy the command into their preferred terminal,
     and actually install Homebrew themselves by approving the install.
     */
    func requestHomebrewInstall() async -> Result {
        var outputLines: [OutputLine] = []

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(CommandCatalog.Onboarding.homebrewInstall, forType: .string)

        // TODO: Remove this if Homebrew can be (fake) installed "externally" via UI tests
        if isSimulatingShellEnvironment {
            fakeHomebrewInstallationForTests()
        }

        appendOutput("onboarding_wizard.output.homebrew_command_copied".localized, .stdOut, to: &outputLines)

        return Result(
            state: .waitingForManualCompletion,
            outputLines: outputLines,
            progress: nil,
            alertState: nil
        )
    }

    /**
     This method checks if Homebrew has been installed, and displays a reminder to install Homebrew if required.

     Once the command has been copied, the user will need to tell PHP Monitor that Homebrew has been installed.
     The app won't be polling the filesystem in the background because that seemed a bit overkill.
     */
    func recheckHomebrew() async -> Result {
        await container.shell.reloadEnvPath()
        let progress = await probe.detectProgress()

        if progress.homebrewInstalled {
            return Result(state: .idle, outputLines: [], progress: progress, alertState: nil)
        }

        return Result(
            state: .waitingForManualCompletion,
            outputLines: OutputLine.errLines(["\n\("onboarding_wizard.output.step_not_resolved".localized)"]),
            progress: progress,
            alertState: nil
        )
    }

    /**
     This automatically fakes a Homebrew installation after the command is copied to the pasteboard.
     It's done because it's difficult to simulate a Terminal interaction without adding a lot of extra code.
     We just complete a dummy interaction that fakes a new Homebrew install on the fake filesystem, instead.

     - Note: Ideally, I'd love to see this replaced. We probably need some sort of external system in place that we can interact
     with to fake the installation of Homebrew. A dummy terminal, perhaps? It should similar to how privileged commands work.
     */
    func fakeHomebrewInstallationForTests() {
        // Execute the install command in the container. In testable configurations, this will result
        // in a "valid" fake Homebrew installation instantly existing!
        container.shell.sync(CommandCatalog.Onboarding.homebrewInstall)
    }
}
