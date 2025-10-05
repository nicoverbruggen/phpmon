//
//  WarningManager+Evaluations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 05/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

extension WarningManager {
    // swiftlint:disable function_body_length
    func allAvailableWarnings() -> [Warning] {
        return [
            Warning(
                command: {
                    return await Shell.pipe("sysctl -n sysctl.proc_translated").out
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
                    return !Shell.PATH.contains("\(Paths.homePath)/.config/phpmon/bin") &&
                        !FileSystem.isWriteableFile("/usr/local/bin/")
                },
                name: "Helpers cannot be symlinked and not in PATH",
                title: "warnings.helper_permissions.title",
                paragraphs: { return [
                    "warnings.helper_permissions.description",
                    "warnings.helper_permissions.unavailable",
                    "warnings.helper_permissions.symlink"
                ] },
                url: "https://github.com/nicoverbruggen/phpmon/wiki/PHP-Monitor-helper-binaries",
                fix: Paths.shell == "/bin/zsh" ? {
                    // Add to PATH
                    await ZshRunCommand().addPhpMonitorPath()
                    // Finally, perform environment checks again
                    await self.checkEnvironment()
                } : nil
            ),
            Warning(
                command: {
                    PhpEnvironments.shared.currentInstall?.extensions.contains { $0.name == "xdebug" } ?? false
                    && !Xdebug.enabled
                },
                name: "Missing configuration file for `xdebug.mode`",
                title: "warnings.xdebug_conf_missing.title",
                paragraphs: { return [
                    "warnings.xdebug_conf_missing.description"
                ] },
                url: "https://xdebug.org/docs/install#mode",
                fix: {
                    if let php = PhpEnvironments.shared.currentInstall {
                        if let xdebug = php.extensions.first(where: { $0.name == "xdebug" }),
                           let original = try? FileSystem.getStringFromFile(xdebug.file) {
                            // Append xdebug.mode = off to the file
                            try? FileSystem.writeAtomicallyToFile(
                                xdebug.file,
                                content: original + "\nxdebug.mode = off"
                            )

                            // Reload extension configuration by updating PHP installation info (reload)
                            PhpEnvironments.shared.currentInstall = ActivePhpInstallation()

                            // Finally, reload warnings
                            await self.checkEnvironment()
                        }
                    }
                }
            ),
            Warning(
                command: {
                    !BrewDiagnostics.installedTaps.contains("shivammathur/php")
                },
                name: "`shivammathur/php` tap is missing",
                title: "warnings.php_tap_missing.title",
                paragraphs: { return [
                    "warnings.php_tap_missing.description"
                ] },
                url: "https://github.com/shivammathur/homebrew-php",
                fix: {
                    await Shell.quiet("brew tap shivammathur/php")
                    await BrewDiagnostics.loadInstalledTaps()
                    await self.checkEnvironment()
                }
            ),
            Warning(
                command: {
                    !BrewDiagnostics.installedTaps.contains("shivammathur/extensions")
                },
                name: "`shivammathur/extensions` tap is missing",
                title: "warnings.extensions_tap_missing.title",
                paragraphs: { return [
                    "warnings.extensions_tap_missing.description"
                ] },
                url: "https://github.com/shivammathur/homebrew-extensions",
                fix: {
                    await Shell.quiet("brew tap shivammathur/extensions")
                    await BrewDiagnostics.loadInstalledTaps()
                    await self.checkEnvironment()
                }
            ),
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
            )
        ]
    }
    // swiftlint:enable function_body_length
}
