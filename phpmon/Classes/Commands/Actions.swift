//
//  Services.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Actions {
    
    public static func detectPhpVersions() -> [String] {
        let files = Shell.user.pipe("ls /usr/local/opt | grep php@")
        var versions = files.components(separatedBy: "\n")
        // Remove all empty strings
        versions.removeAll { (string) -> Bool in
            return (string == "")
        }
        // Get a list of versions only
        var versionsOnly : [String] = []
        versions.forEach { (string) in
            versionsOnly.append(string.components(separatedBy: "php@")[1])
        }
        return versionsOnly
    }
    
    public static func restartPhpFpm() {
        let version = App.shared.currentVersion!.short
        if (version == App.shared.brewPhpVersion) {
            Shell.user.run("sudo brew services restart php")
        } else {
            Shell.user.run("sudo brew services restart php@\(version)")
        }
    }
    
    public static func restartNginx()
    {
        Shell.user.run("sudo brew services restart nginx")
    }
    
    public static func switchToPhpVersion(version: String, availableVersions: [String]) {
        availableVersions.forEach { (version) in
            // Unlink the current version
            Shell.user.run("brew unlink php@\(version)")
            // Stop the services
            if (version == App.shared.brewPhpVersion) {
                Shell.user.run("sudo brew services stop php")
            } else {
                Shell.user.run("sudo brew services stop php@\(version)")
            }
        }
        if (availableVersions.contains(App.shared.brewPhpVersion)) {
            // Use the latest version as a default
            Shell.user.run("brew link php@\(App.shared.brewPhpVersion) --overwrite --force")
            if (version == App.shared.brewPhpVersion) {
                // If said version was also requested, all we need to do is start the service
                Shell.user.run("sudo brew services start php")
            } else {
                // Otherwise, link the correct php version + start the correct service
                Shell.user.run("brew link php@\(version) --overwrite --force")
                Shell.user.run("sudo brew services start php@\(version)")
            }
        }
    }
    
    public static func openGenericPhpConfigFolder() {
        let files = [NSURL(fileURLWithPath: "/usr/local/etc/php")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openPhpConfigFolder(version: String) {
        let files = [NSURL(fileURLWithPath: "/usr/local/etc/php/\(version)/php.ini")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openValetConfigFolder() {
        let files = [NSURL(fileURLWithPath: NSString(string: "~/.config/valet").expandingTildeInPath)];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func didFindXdebug(_ version: String) -> Bool {
        let command = """
        grep -q 'zend_extension="xdebug.so"' /usr/local/etc/php/\(version)/php.ini; [ $? -eq 0 ] && echo "YES" || echo "NO"
        """
        let output = Shell.user.pipe(command).trimmingCharacters(in: .whitespacesAndNewlines)
        return (output == "YES")
    }
    
    public static func didEnableXdebug(_ version: String) -> Bool {
        let command = """
        grep -q '; zend_extension="xdebug.so"' /usr/local/etc/php/\(version)/php.ini; [ $? -eq 0 ] && echo "YES" || echo "NO"
        """
        let output = Shell.user.pipe(command).trimmingCharacters(in: .whitespacesAndNewlines)
        return (output == "NO")
    }
    
    public static func toggleXdebug() {
        let version = App.shared.currentVersion?.short
        var command = """
        sed -i '' 's/; zend_extension="xdebug.so"/zend_extension="xdebug.so"/g' /usr/local/etc/php/\(version!)/php.ini
        """
        if (self.didEnableXdebug(version!)) {
            command = """
            sed -i '' 's/zend_extension="xdebug.so"/; zend_extension="xdebug.so"/g' /usr/local/etc/php/\(version!)/php.ini
            """
        }
        Shell.user.run(command)
    }
    
    // unlink all the crap and link the latest version
    // this also restarts all services
    public static func fixMyPhp() {
        let versions = self.detectPhpVersions()
        versions.forEach { (version) in
            Shell.user.run("brew unlink php@\(version)")
            if (version == App.shared.brewPhpVersion) {
                Shell.user.run("brew services stop php")
                Shell.user.run("sudo brew services stop php")
            } else {
                Shell.user.run("brew services stop php@\(version)")
                Shell.user.run("sudo brew services stop php@\(version)")
            }
        }
        Shell.user.run("brew services stop php")
        Shell.user.run("brew services stop nginx")
        Shell.user.run("brew link php")
        Shell.user.run("sudo brew services restart php")
        Shell.user.run("sudo brew services restart nginx")
    }
}
