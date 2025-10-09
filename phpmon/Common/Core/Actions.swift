//
//  Services.swift
//  PHP Monitor
//
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit
import ContainerMacro

@ContainerAccess
class Actions {
    // MARK: - Services

    public func linkPhp() async {
        await brew("link php --overwrite --force")
    }

    public func restartPhpFpm() async {
        await brew("services restart \(HomebrewFormulae.php)", sudo: HomebrewFormulae.php.elevated)
    }

    public func restartPhpFpm(version: String) async {
        let formula = (version == PhpEnvironments.brewPhpAlias) ? "php" : "php@\(version)"
        await brew("services restart \(formula)", sudo: HomebrewFormulae.php.elevated)
    }

    public func restartNginx() async {
        await brew("services restart \(HomebrewFormulae.nginx)", sudo: HomebrewFormulae.nginx.elevated)
    }

    public func restartDnsMasq() async {
        await brew("services restart \(HomebrewFormulae.dnsmasq)", sudo: HomebrewFormulae.dnsmasq.elevated)
    }

    public func stopValetServices() async {
        await brew("services stop \(HomebrewFormulae.php)", sudo: HomebrewFormulae.php.elevated)
        await brew("services stop \(HomebrewFormulae.nginx)", sudo: HomebrewFormulae.nginx.elevated)
        await brew("services stop \(HomebrewFormulae.dnsmasq)", sudo: HomebrewFormulae.dnsmasq.elevated)
    }

    public func fixHomebrewPermissions() throws {
        var servicesCommands = [
            "\(paths.brew) services stop \(HomebrewFormulae.nginx)",
            "\(paths.brew) services stop \(HomebrewFormulae.dnsmasq)"
        ]

        var cellarCommands = [
            "chown -R \(paths.whoami):admin \(paths.cellarPath)/\(HomebrewFormulae.nginx)",
            "chown -R \(paths.whoami):admin \(paths.cellarPath)/\(HomebrewFormulae.dnsmasq)"
        ]

        PhpEnvironments.shared.availablePhpVersions.forEach { version in
            let formula = version == PhpEnvironments.brewPhpAlias
                ? "php"
                : "php@\(version)"
            servicesCommands.append("\(paths.brew) services stop \(formula)")
            cellarCommands.append("chown -R \(paths.whoami):admin \(paths.cellarPath)/\(formula)")
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

    public func openGenericPhpConfigFolder() {
        let files = [NSURL(fileURLWithPath: "\(paths.etcPath)/php")]
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }

    public func openPhpConfigFolder(version: String) {
        let files = [NSURL(fileURLWithPath: "\(paths.etcPath)/php/\(version)/php.ini")]
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }

    public func openGlobalComposerFolder() {
        let file = URL(string: "file://~/.composer/composer.json".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    public func openValetConfigFolder() {
        let file = URL(string: "file://~/.config/valet".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    public func openPhpMonitorConfigFile() {
        let file = URL(string: "file://~/.config/phpmon".replacingTildeWithHomeDirectory)!
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    // MARK: - Other Actions

    public func createTempPhpInfoFile() async -> URL {
        try! filesystem.writeAtomicallyToFile("/tmp/phpmon_phpinfo.php", content: "<?php phpinfo();")

        // Tell php-cgi to run the PHP and output as an .html file
        await shell.quiet("\(paths.binPath)/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html")

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
    public func fixMyValet() async {
        await InternalSwitcher().performSwitch(to: PhpEnvironments.brewPhpAlias)
        await brew("services restart \(HomebrewFormulae.dnsmasq)", sudo: HomebrewFormulae.dnsmasq.elevated)
        await brew("services restart \(HomebrewFormulae.php)", sudo: HomebrewFormulae.php.elevated)
        await brew("services restart \(HomebrewFormulae.nginx)", sudo: HomebrewFormulae.nginx.elevated)
    }
}
