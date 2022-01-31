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
    
    /**
     Kindly asks Valet to switch to a specific PHP version.
     */
    public static func switchToPhpVersionUsingValet(
        version: String,
        availableVersions: [String],
        completed: @escaping () -> Void
    ) {
        Log.info("Switching to \(version) using Valet")
        Log.info(valet("use php@\(version)"))
        completed()
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
     
     After this, the brew services are also stopped,
     the latest PHP version is linked, and php + nginx are restarted.
     
     If this does not solve the issue, the user may need to install additional
     extensions and/or run `composer global update`.
     */
    public static func fixMyValet()
    {
        brew("services restart dnsmasq", sudo: true)
        
        PhpEnv.shared.detectPhpVersions().forEach { (version) in
            let formula = (version == PhpEnv.brewPhpVersion) ? "php" : "php@\(version)"
            brew("unlink php@\(version)")
            brew("services stop \(formula)")
            brew("services stop \(formula)", sudo: true)
        }
        
        brew("services stop dnsmasq")
        brew("services stop php")
        brew("services stop nginx")
        
        brew("link php --force")
        
        brew("services restart dnsmasq", sudo: true)
        brew("services restart php", sudo: true)
        brew("services restart nginx", sudo: true)
    }
}
