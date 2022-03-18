//
//  Services.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Actions {
    
    // MARK: - Services
    
    public static func restartPhpFpm()
    {
        brew("services restart \(PhpEnv.phpInstall.formula)", sudo: true)
    }
    
    public static func restartNginx()
    {
        brew("services restart nginx", sudo: true)
    }
    
    public static func restartDnsMasq()
    {
        brew("services restart dnsmasq", sudo: true)
    }
    
    public static func stopAllServices()
    {
        brew("services stop \(PhpEnv.phpInstall.formula)", sudo: true)
        brew("services stop nginx", sudo: true)
        brew("services stop dnsmasq", sudo: true)
    }
    
    public static func fixHomebrewPermissions() throws
    {
        var servicesCommands = [
            "\(Paths.brew) services stop nginx",
            "\(Paths.brew) services stop dnsmasq",
        ]
        var cellarCommands = [
            "chown -R \(Paths.whoami):staff \(Paths.cellarPath)/nginx",
            "chown -R \(Paths.whoami):staff \(Paths.cellarPath)/dnsmasq"
        ]
        
        PhpEnv.shared.availablePhpVersions.forEach { version in
            let formula = version == PhpEnv.brewPhpVersion
                ? "php"
                : "php@\(version)"
            servicesCommands.append("\(Paths.brew) services stop \(formula)")
            cellarCommands.append("chown -R \(Paths.whoami):staff \(Paths.cellarPath)/\(formula)")
        }
        
        let script =
            servicesCommands.joined(separator: " && ")
            + " && "
            + cellarCommands.joined(separator: " && ")
        
        let appleScript = NSAppleScript(
            source: "do shell script \"\(script)\" with administrator privileges"
        )
        
        let eventResult: NSAppleEventDescriptor? = appleScript?.executeAndReturnError(nil)
        
        if (eventResult == nil) {
            throw HomebrewPermissionError(kind: .applescriptNilError)
        }
    }
    
    // MARK: - Finding Config Files
    
    public static func openGenericPhpConfigFolder()
    {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openGlobalComposerFolder()
    {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".composer/composer.json")
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }
    
    public static func openPhpConfigFolder(version: String)
    {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php/\(version)/php.ini")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openValetConfigFolder()
    {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/valet")
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }

    // MARK: - Other Actions
    
    public static func createTempPhpInfoFile() -> URL
    {
        // Write a file called `phpmon_phpinfo.php` to /tmp
        try! "<?php phpinfo();".write(toFile: "/tmp/phpmon_phpinfo.php", atomically: true, encoding: .utf8)
        
        // Tell php-cgi to run the PHP and output as an .html file
        Shell.run("\(Paths.binPath)/php-cgi -q /tmp/phpmon_phpinfo.php > /tmp/phpmon_phpinfo.html")
        
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
    public static func fixMyValet(completed: @escaping () -> Void)
    {
        InternalSwitcher().performSwitch(to: PhpEnv.brewPhpVersion, completion: {
            brew("services restart dnsmasq", sudo: true)
            brew("services restart php", sudo: true)
            brew("services restart nginx", sudo: true)
            completed()
        })
    }
}
