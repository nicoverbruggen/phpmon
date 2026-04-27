//
//  OnboardingWizardViewModel+Steps.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 22/04/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import AppKit

extension OnboardingWizardViewModel {
    private var isSimulatingShellEnvironment: Bool {
        App.hasLoadedTestableConfiguration || container.shell is TestableShell
    }

    func requestDeveloperToolsInstall() async {
        outputLines = []
        state = .running

        let output = await container.shell.pipe(Toolchain.Commands.developerToolsInstall)
        appendIfPresent(output)

        hasTriggeredDeveloperToolsInstall = true
        state = .waitingForManualCompletion
        appendOutput("onboarding_wizard.output.developer_tools_requested".localized, .stdOut)
    }

    func recheckDeveloperTools() async {
        state = .running
        await refreshProgress()

        if progress.developerToolsInstalled {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
            onDeveloperToolsRecheckFailed?()
        }
    }

    func requestHomebrewInstall() async {
        outputLines = []
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(Toolchain.Commands.homebrewInstall, forType: .string)

        if isSimulatingShellEnvironment {
            let output = container.shell.sync(Toolchain.Commands.homebrewInstall)
            appendIfPresent(output)
        }

        hasTriggeredHomebrewInstall = true
        state = .waitingForManualCompletion
        appendOutput("onboarding_wizard.output.homebrew_command_copied".localized, .stdOut)
    }

    func recheckHomebrew() async {
        state = .running
        await container.shell.reloadEnvPath()
        await refreshProgress()

        if progress.homebrewInstalled {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func fixPathAutomatically() async {
        outputLines = []
        state = .running

        let zshRunCommand = ZshRunCommand(container)
        appendOutput("onboarding_wizard.output.path_updating".localized, .stdOut)

        let phpMonitorResult = await zshRunCommand.addPhpMonitorBinPath()
        let composerResult = await zshRunCommand.addComposerBinPath()
        let homebrewResult = await zshRunCommand.addHomebrewBinPath()

        await container.shell.reloadEnvPath()
        await refreshProgress()

        let allFilesUpdated = phpMonitorResult && composerResult && homebrewResult

        if allFilesUpdated && progress.pathConfigured {
            finalize(success: true)
        } else if allFilesUpdated {
            state = .waitingForManualCompletion
            appendOutput("onboarding_wizard.output.path_reopen_shell".localized, .stdOut)
        } else {
            finalize(success: false)
        }
    }

    func recheckPath() async {
        state = .running
        await container.shell.reloadEnvPath()
        await refreshProgress()

        if progress.pathConfigured {
            outputLines = []
            state = .idle
        } else {
            state = .waitingForManualCompletion
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    func installPhpComposer() async {
        outputLines = []
        state = .running

        do {
            for command in Toolchain.Commands.phpComposerInstall(using: container.paths.brew) {
                try await attachStreaming(command)
            }
        } catch {
            failStep(error)
            return
        }

        await refreshProgress()
        finalize(success: progress.phpInstalled && progress.composerInstalled)
    }

    func installValet() async {
        outputLines = []
        state = .running

        container.paths.detectBinaryPaths()
        let brew = container.paths.brew
        let composer = container.paths.composer ?? "composer"
        let composerValetShim = "\(container.paths.homePath)/.composer/vendor/bin/valet"
        let composerValetScript = "\(container.paths.homePath)/.composer/vendor/laravel/valet/valet"
        let homebrewValet = container.paths.valet

        var sudoersInstalled = false
        defer {
            if sudoersInstalled && !Self.removeValetSudoers() {
                onValetSudoersRemovalFailed?()
            }
        }

        if !isSimulatingShellEnvironment {
            do {
                try Self.installValetSudoers(forScriptAt: composerValetScript)
                sudoersInstalled = true
            } catch {
                failStep(error)
                return
            }
        }

        do {
            for command in Toolchain.Commands.valetInstall(
                using: brew,
                composer: composer,
                valet: composerValetShim
            ) {
                try await attachStreaming(command)
            }

            try await attachStreaming(Toolchain.Commands.valetTrust(using: homebrewValet))
        } catch {
            failStep(error)
            return
        }

        await refreshProgress()
        finalize(success: progress.valetInstalled && progress.valetTrusted)
    }

    // MARK: - Shared helpers

    private func appendIfPresent(_ output: ShellOutput) {
        if !output.out.isEmpty { appendOutput(output.out, .stdOut) }
        if !output.err.isEmpty { appendOutput(output.err, .stdErr) }
    }

    private func attachStreaming(_ command: String, timeout: TimeInterval = 600) async throws {
        try await container.shell.attach(
            command,
            didReceiveOutput: { [weak self] text, stream in
                Task { @MainActor in
                    self?.appendOutput(text, stream)
                }
            },
            withTimeout: timeout
        )
    }

    private func finalize(success: Bool) {
        if success {
            state = .idle
            appendOutput("\n\("onboarding_wizard.output.step_completed".localized)", .stdOut)
        } else {
            state = .failed
            appendOutput("\n\("onboarding_wizard.output.step_not_resolved".localized)", .stdErr)
        }
    }

    private func failStep(_ error: Error) {
        state = .failed
        appendOutput("\nError: \(error.localizedDescription)", .stdErr)
    }

    // MARK: - Temporary sudoers entry for `valet install` and `valet trust`

    private static let valetSudoersPath = "/etc/sudoers.d/phpmon-valet-onboarding"
    private static let valetSudoersTemp = "/tmp/phpmon-valet-onboarding.sudoers"
    static let valetSudoersCleanupCommand = "sudo rm -f \(valetSudoersPath) \(valetSudoersTemp)"

    fileprivate static func installValetSudoers(forScriptAt valetPath: String) throws {
        let entry = "Cmnd_Alias VALET_PHPMON = \(valetPath) install, \(valetPath) trust"
        let perm = "%admin ALL=(root) NOPASSWD:SETENV: VALET_PHPMON"
        let temp = valetSudoersTemp
        let dest = valetSudoersPath
        let script = [
            "rm -f \(temp)",
            "echo '\(entry)' > \(temp)",
            "echo '\(perm)' >> \(temp)",
            "/usr/sbin/visudo -cf \(temp)",
            "chmod 0440 \(temp)",
            "chown root:wheel \(temp)",
            "mv \(temp) \(dest)"
        ].joined(separator: " && ")
        try AppleScript.runSimpleShellAsAdmin(script)
    }

    fileprivate static func removeValetSudoers() -> Bool {
        do {
            try AppleScript.runSimpleShellAsAdmin("rm -f \(valetSudoersPath) \(valetSudoersTemp)")
            return true
        } catch {
            Log.warn("Failed to remove temporary Valet sudoers entry after onboarding: \(error)")
            return false
        }
    }
}
