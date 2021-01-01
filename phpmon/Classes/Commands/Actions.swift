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
        let files = Shell.user.pipe("ls \(Paths.optPath()) | grep php@")
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
        
        // Make sure the aliased version is detected
        // The user may have `php` installed, but not e.g. `php@8.0`
        // We should also detect that as a version that is installed
        let phpAlias = App.shared.brewPhpVersion
        if (!versionsOnly.contains(phpAlias)) {
            versionsOnly.append(phpAlias);
        }
        
        return versionsOnly
    }
    
    public static func restartPhpFpm() {
        let version = App.shared.currentVersion!.short
        if (version == App.shared.brewPhpVersion) {
            Shell.user.run("sudo \(Paths.brew()) services restart php")
        } else {
            Shell.user.run("sudo \(Paths.brew()) services restart php@\(version)")
        }
    }
    
    public static func restartNginx()
    {
        Shell.user.run("sudo \(Paths.brew()) services restart nginx")
    }
    
    /**
     Switching to a new PHP version involves:
     - unlinking the current version
     - stopping the active services
     - linking the new desired version
     
     Please note that depending on which version is installed,
     the version that is switched to may or may not be identical to `php` (without @version).
     */
    public static func switchToPhpVersion(version: String, availableVersions: [String]) {
        availableVersions.forEach { (available) in
            let formula = (available == App.shared.brewPhpVersion) ? "php" : "php@\(available)"
            Shell.user.run("\(Paths.brew()) unlink \(formula)")
            Shell.user.run("sudo \(Paths.brew()) services stop \(formula)")
        }
        
        let formula = (version == App.shared.brewPhpVersion) ? "php" : "php@\(version)"
        Shell.user.run("\(Paths.brew()) link \(formula) --overwrite --force")
        Shell.user.run("sudo \(Paths.brew()) services start \(formula)")
    }
    
    public static func openGenericPhpConfigFolder() {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath())/php")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openPhpConfigFolder(version: String) {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath())/php/\(version)/php.ini")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openValetConfigFolder() {
        let files = [NSURL(fileURLWithPath: NSString(string: "~/.config/valet").expandingTildeInPath)];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func didFindXdebug(_ version: String) -> Bool {
        let command = """
        grep -q 'zend_extension="xdebug.so"' \(Paths.etcPath())/php/\(version)/php.ini; [ $? -eq 0 ] && echo "YES" || echo "NO"
        """
        let output = Shell.user.pipe(command).trimmingCharacters(in: .whitespacesAndNewlines)
        return (output == "YES")
    }
    
    public static func didEnableXdebug(_ version: String) -> Bool {
        let command = """
        grep -q '; zend_extension="xdebug.so"' \(Paths.etcPath())/php/\(version)/php.ini; [ $? -eq 0 ] && echo "YES" || echo "NO"
        """
        let output = Shell.user.pipe(command).trimmingCharacters(in: .whitespacesAndNewlines)
        return (output == "NO")
    }
    
    public static func toggleXdebug() {
        let version = App.shared.currentVersion?.short
        var command = """
        sed -i '' 's/; zend_extension="xdebug.so"/zend_extension="xdebug.so"/g' \(Paths.etcPath())/php/\(version!)/php.ini
        """
        if (self.didEnableXdebug(version!)) {
            command = """
            sed -i '' 's/zend_extension="xdebug.so"/; zend_extension="xdebug.so"/g' \(Paths.etcPath())/php/\(version!)/php.ini
            """
        }
        Shell.user.run(command)
    }
    
    /**
     Detects all currently available PHP versions, and unlinks each and every one of them.
     After this, the brew services are also stopped, the latest PHP version is linked, and php + nginx are restarted.
     If this does not solve the issue, the user may need to install additional extensions and/or run `composer global update`.
     */
    public static func fixMyPhp() {
        let versions = self.detectPhpVersions()
        versions.forEach { (version) in
            Shell.user.run("\(Paths.brew()) unlink php@\(version)")
            if (version == App.shared.brewPhpVersion) {
                Shell.user.run("\(Paths.brew()) services stop php")
                Shell.user.run("sudo \(Paths.brew()) services stop php")
            } else {
                Shell.user.run("\(Paths.brew()) services stop php@\(version)")
                Shell.user.run("sudo \(Paths.brew()) services stop php@\(version)")
            }
        }
        Shell.user.run("\(Paths.brew()) services stop php")
        Shell.user.run("\(Paths.brew()) services stop nginx")
        Shell.user.run("\(Paths.brew()) link php")
        Shell.user.run("sudo \(Paths.brew()) services restart php")
        Shell.user.run("sudo \(Paths.brew()) services restart nginx")
    }
}
