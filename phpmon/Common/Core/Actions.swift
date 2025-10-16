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
    var formulae: HomebrewFormulae {
        return HomebrewFormulae(App.shared.container)
    }

    var paths: Paths {
        return container.paths
    }

    // MARK: - Services

    public func linkPhp() async {
        await brew(container, "link php --overwrite --force")
    }

    public func restartPhpFpm() async {
        await brew(container, "services restart \(formulae.php)", sudo: formulae.php.elevated)
    }

    public func restartPhpFpm(version: String) async {
        let formula = (version == PhpEnvironments.brewPhpAlias) ? "php" : "php@\(version)"
        await brew(container, "services restart \(formula)", sudo: formulae.php.elevated)
    }

    public func restartNginx() async {
        await brew(container, "services restart \(formulae.nginx)", sudo: formulae.nginx.elevated)
    }

    public func restartDnsMasq() async {
        await brew(container, "services restart \(formulae.dnsmasq)", sudo: formulae.dnsmasq.elevated)
    }

    public func stopValetServices() async {
        await brew(container, "services stop \(formulae.php)", sudo: formulae.php.elevated)
        await brew(container, "services stop \(formulae.nginx)", sudo: formulae.nginx.elevated)
        await brew(container, "services stop \(formulae.dnsmasq)", sudo: formulae.dnsmasq.elevated)
    }

    public func fixHomebrewPermissions() throws {
        var servicesCommands = [
            "\(paths.brew) services stop \(formulae.nginx)",
            "\(paths.brew) services stop \(formulae.dnsmasq)"
        ]

        var cellarCommands = [
            "chown -R \(paths.whoami):admin \(paths.cellarPath)/\(formulae.nginx)",
            "chown -R \(paths.whoami):admin \(paths.cellarPath)/\(formulae.dnsmasq)"
        ]

        App.shared.container.phpEnvs.availablePhpVersions.forEach { version in
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
        try! container.filesystem.writeAtomicallyToFile("/tmp/phpmon_phpinfo.php", content: "<?php phpinfo();")

        // Tell php-cgi to run the PHP and output as an .html file
        await container.shell.quiet("\(paths.binPath)/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html")

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
        await InternalSwitcher(container).performSwitch(to: PhpEnvironments.brewPhpAlias)
        await brew(container, "services restart \(formulae.dnsmasq)", sudo: formulae.dnsmasq.elevated)
        await brew(container, "services restart \(formulae.php)", sudo: formulae.php.elevated)
        await brew(container, "services restart \(formulae.nginx)", sudo: formulae.nginx.elevated)
    }
}
