//
//  Services.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Actions {

    // MARK: - Services

    public static func linkPhp() async {
        await brew("link php --overwrite --force")

        // TODO: Verify that this worked, if not, notify the user
    }

    public static func restartPhpFpm() async {
        await brew("services restart \(Homebrew.Formulae.php)", sudo: Homebrew.Formulae.php.elevated)
    }

    public static func restartNginx() async {
        await brew("services restart \(Homebrew.Formulae.nginx)", sudo: Homebrew.Formulae.nginx.elevated)
    }

    public static func restartDnsMasq() async {
        await brew("services restart \(Homebrew.Formulae.dnsmasq)", sudo: Homebrew.Formulae.dnsmasq.elevated)
    }

    public static func stopValetServices() async {
        await brew("services stop \(Homebrew.Formulae.php)", sudo: Homebrew.Formulae.php.elevated)
        await brew("services stop \(Homebrew.Formulae.nginx)", sudo: Homebrew.Formulae.nginx.elevated)
        await brew("services stop \(Homebrew.Formulae.dnsmasq)", sudo: Homebrew.Formulae.dnsmasq.elevated)
    }

    public static func fixHomebrewPermissions() throws {
        var servicesCommands = [
            "\(Paths.brew) services stop \(Homebrew.Formulae.nginx)",
            "\(Paths.brew) services stop \(Homebrew.Formulae.dnsmasq)"
        ]

        var cellarCommands = [
            "chown -R \(Paths.whoami):admin \(Paths.cellarPath)/\(Homebrew.Formulae.nginx)",
            "chown -R \(Paths.whoami):admin \(Paths.cellarPath)/\(Homebrew.Formulae.dnsmasq)"
        ]

        PhpEnv.shared.availablePhpVersions.forEach { version in
            let formula = version == PhpEnv.brewPhpAlias
                ? "php"
                : "php@\(version)"
            servicesCommands.append("\(Paths.brew) services stop \(formula)")
            cellarCommands.append("chown -R \(Paths.whoami):admin \(Paths.cellarPath)/\(formula)")
        }

        let script =
            servicesCommands.joined(separator: " && ")
            + " && "
            + cellarCommands.joined(separator: " && ")

        let source = "do shell script \"\(script)\" with administrator privileges"

        Log.perf(source)
        let appleScript = NSAppleScript(source: source)

        let eventResult: NSAppleEventDescriptor? = appleScript?.executeAndReturnError(nil)

        if eventResult == nil {
            throw HomebrewPermissionError(kind: .applescriptNilError)
        }
    }

    // MARK: - Finding Config Files

    public static func openGenericPhpConfigFolder() {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php")]
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }

    public static func openPhpConfigFolder(version: String) {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php/\(version)/php.ini")]
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }

    public static func openGlobalComposerFolder() {
        let file = URL(string: "file://~/.composer/composer.json".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    public static func openValetConfigFolder() {
        let file = URL(string: "file://~/.config/valet".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    public static func openPhpMonitorConfigFile() {
        let file = URL(string: "file://~/.config/phpmon".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    // MARK: - Other Actions

    public static func createTempPhpInfoFile() async -> URL {
        try! FileSystem.writeAtomicallyToFile("/tmp/phpmon_phpinfo.php", content: "<?php phpinfo();")

        // Tell php-cgi to run the PHP and output as an .html file
        await Shell.quiet("\(Paths.binPath)/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html")

        return URL(string: "file:///private/tmp/phpmon_phpinfo.html")!
    }

    // MARK: - Fix My Valet

    /**
     Detects all currently available PHP versions,
     and unlinks each and every one of them.
     
     This all happens in sequence, nothing runs in parallel.
     
     After this, the brew services are also stopped,
     the latest PHP version is linked, and php + nginx are restarted.
     
     If this does not solve the issue, the user may need to install additional
     extensions and/or run `composer global update`.
     */
    public static func fixMyValet() async {
        await InternalSwitcher().performSwitch(to: PhpEnv.brewPhpAlias)
        await brew("services restart \(Homebrew.Formulae.dnsmasq)", sudo: Homebrew.Formulae.dnsmasq.elevated)
        await brew("services restart \(Homebrew.Formulae.php)", sudo: Homebrew.Formulae.php.elevated)
        await brew("services restart \(Homebrew.Formulae.nginx)", sudo: Homebrew.Formulae.nginx.elevated)
    }

    public static func installPhpVersion(version: String) async {
        let subject = ProgressViewSubject(
            title: "Installing PHP \(version)",
            description: "Please wait while Homebrew installs PHP \(version)..."
        )

        let installables = [
            "8.2": "php",
            "8.1": "php@8.1",
            "8.0": "php@8.0",
            "7.4": "shivammathur/php/php@7.4",
            "7.3": "shivammathur/php/php@7.3",
            "7.2": "shivammathur/php/php@7.2",
            "7.1": "shivammathur/php/php@7.1",
            "7.0": "shivammathur/php/php@7.0"
        ]

        if installables.keys.contains(version) {
            let window = await ProgressWindowView.display(subject)
            let formula = installables[version]!
            if formula.contains("shivammathur") && !HomebrewDiagnostics.installedTaps.contains("shivammathur/php") {
                await Shell.quiet("brew tap shivammathur/php")
            }
            // TODO: Attempt to read the progress of this
            // Use the same way the composer progress is read
            await brew("install \(formula)", sudo: false)
            await PhpEnv.detectPhpVersions()
            await MainMenu.shared.refreshActiveInstallation()
            await window.close()
        }
    }
}
