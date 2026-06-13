//
//  WarningManager+Evaluations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

extension WarningManager {
    // swiftlint:disable function_body_length
    func allAvailableWarnings() -> [Warning] {
        return [
            // SYSTEM
            Warning(
                command: {
                    return await self.container.shell.pipe("sysctl -n sysctl.proc_translated").out
                        .trimmingCharacters(in: .whitespacesAndNewlines) == "1"
                },
                name: "Running PHP Monitor with Rosetta on Apple Silicon",
                title: "warnings.arm_compatibility.title",
                paragraphs: { return ["warnings.arm_compatibility.description"] },
                url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-and-Apple-Silicon",
                fix: nil
            ),
            Warning(
                command: {
                    return self.container.paths.isConfiguredShellValid &&
                        !self.container.shell.PATH.contains("\(self.container.paths.homePath)/.config/phpmon/bin") &&
                        !self.container.filesystem.isWriteableFile("/usr/local/bin/")
                },
                name: "Helpers cannot be symlinked and not in PATH",
                title: "warnings.helper_permissions.title",
                paragraphs: { return [
                    "warnings.helper_permissions.description",
                    "warnings.helper_permissions.unavailable",
                    "warnings.helper_permissions.symlink"
                ] },
                url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries",
                fix: self.container.paths.isConfiguredShellValid && self.container.paths.shell == "/bin/zsh" ? {
                    // Add to PATH
                    await ZshRunCommand(self.container).addPhpMonitorBinPath()
                    // Finally, perform environment checks again
                    await self.checkEnvironment()
                } : nil
            ),
            Warning(
                command: {
                    return !self.container.paths.isConfiguredShellValid
                },
                name: "Configured shell path is invalid",
                title: "warnings.invalid_shell.title",
                paragraphs: { return [
                    "warnings.invalid_shell.description".localized(
                        self.container.paths.configuredShellPath,
                        self.container.paths.shell
                    ),
                    "warnings.invalid_shell.manual_fix".localized(self.container.paths.shell)
                ] },
                url: nil,
                fix: nil
            ),
            Warning(
                command: {
                    self.container.phpEnvs.currentInstall?.extensions.contains { $0.name == "xdebug" } ?? false
                    && !Xdebug(self.container).enabled
                },
                name: "Missing configuration file for `xdebug.mode`",
                title: "warnings.xdebug_conf_missing.title",
                paragraphs: { return [
                    "warnings.xdebug_conf_missing.description"
                ] },
                url: "https://xdebug.org/docs/install#mode",
                fix: {
                    if let php = self.container.phpEnvs.currentInstall {
                        if let xdebug = php.extensions.first(where: { $0.name == "xdebug" }),
                           let original = try? self.container.filesystem.getStringFromFile(xdebug.file) {
                            // Append xdebug.mode = off to the file
                            try? self.container.filesystem.writeAtomicallyToFile(
                                xdebug.file,
                                content: original + "\nxdebug.mode = off"
                            )

                            // Reload extension configuration by updating PHP installation info (reload)
                            self.container.phpEnvs.currentInstall = ActivePhpInstallation(self.container)

                            // Finally, reload warnings
                            await self.checkEnvironment()
                        }
                    }
                }
            ),

            // HOMEBREW
            Warning(
                command: {
                    !self.brewDiagnostics.missingRequiredPhpTaps().isEmpty
                },
                name: "Required Homebrew taps are missing",
                title: "warnings.required_taps_missing.title",
                paragraphs: { return [
                    "warnings.required_taps_missing.description"
                ] },
                url: "https://github.com/shivammathur/homebrew-php",
                fix: {
                    await self.fixMissingRequiredTaps()
                    await self.checkEnvironment()
                }
            ),
            Warning(
                command: {
                    guard self.brewDiagnostics.missingRequiredPhpTaps().isEmpty else {
                        return false
                    }

                    let untrusted = await self.brewDiagnostics.untrustedRequiredPhpTaps()
                    return !untrusted.isEmpty
                },
                name: "Required Homebrew taps are not trusted",
                title: "warnings.required_taps_untrusted.title",
                paragraphs: { return [
                    "warnings.required_taps_untrusted.description"
                ] },
                url: "https://github.com/shivammathur/homebrew-php",
                fix: {
                    await self.fixUntrustedRequiredTaps()
                    await self.checkEnvironment()
                }
            ),

            // PHP
            Warning(
                command: {
                    PhpConfigChecker.shared.check()
                    return !PhpConfigChecker.shared.missing.isEmpty
                },
                name: "Your PHP installation is missing configuration files",
                title: "warnings.files_missing.title",
                paragraphs: { return [
                    "warnings.files_missing.description".localized(
                        PhpConfigChecker.shared.missing.joined(separator: "\n• ")
                    )
                ] },
                url: nil,
                fix: nil
            ),

            // VALET
            Warning(
                command: {
                    if Valet.installed {
                        return !Valet.getExpiredDomainListable().isEmpty
                    }

                    return false
                },
                name: "One or more domain certificates expired",
                title: "warnings.certificates_expired.title",
                paragraphs: { return ["warnings.certificates_expired.description"] },
                url: nil,
                fix: {
                    await DomainListVC.show()

                    if let vc = await WindowManager
                        .controller(of: DomainListWC.self)?
                        .window?.contentViewController as? DomainListVC {
                        await vc.checkForCertificateRenewal {
                            await self.checkEnvironment()
                        }
                    }
                }
            )
        ]
    }
    // swiftlint:enable function_body_length

    /// Taps whichever required PHP taps aren't installed yet, in a single fix.
    private func fixMissingRequiredTaps() async {
        let brew = container.paths.brew
        let installed = brewDiagnostics.installedTaps

        let commands: [ConditionalCommand] = [
            .command("\(brew) tap \(Constants.Taps.php)",
                     when: !installed.contains(Constants.Taps.php)),
            .command("\(brew) tap \(Constants.Taps.extensions)",
                     when: !installed.contains(Constants.Taps.extensions))
        ]

        for command in commands.included {
            await container.shell.pipe(command)
        }

        await brewDiagnostics.loadInstalledTaps()
        await brewDiagnostics.loadTrustedTaps()
    }

    /// Trusts whichever required PHP taps aren't trusted yet, in a single fix.
    private func fixUntrustedRequiredTaps() async {
        let brew = container.paths.brew
        let untrusted = await brewDiagnostics.untrustedRequiredPhpTaps()

        let commands: [ConditionalCommand] = [
            .command("\(brew) trust --tap \(Constants.Taps.php)",
                     when: untrusted.contains(Constants.Taps.php)),
            .command("\(brew) trust --tap \(Constants.Taps.extensions)",
                     when: untrusted.contains(Constants.Taps.extensions))
        ]

        for command in commands.included {
            await container.shell.pipe(command)
        }

        await brewDiagnostics.loadInstalledTaps()
        await brewDiagnostics.loadTrustedTaps()
    }
}
