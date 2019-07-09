//
//  Services.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Services {
    public static func mysqlIsRunning() -> Bool {
        let running = Shell.shared.pipe( "launchctl list | grep homebrew.mxcl.mysql")
        return (running != "")
    }
    
    public static func nginxIsRunning() -> Bool {
        let running = Shell.shared.pipe( "launchctl list | grep homebrew.mxcl.nginx")
        return (running != "")
    }
    
    public static func detectPhpVersions() -> [String] {
        let files = Shell.shared.pipe( "ls /usr/local/opt | grep php@")
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
    
    public static func switchToPhpVersion(version: String, availableVersions: [String]) {
        availableVersions.forEach { (version) in
            Shell.shared.run( "brew unlink php@\(version)")
        }
        if (availableVersions.contains("7.3")) {
            Shell.shared.run( "brew link php@7.3")
            if (version == Constants.LatestPhpVersion) {
                Shell.shared.run( "valet use php")
            } else {
                Shell.shared.run( "valet use php@\(version)")
            }
        }
    }
    
    public static func restartPhp(version: String) {
        Shell.shared.run( "brew services restart php@\(version)")
    }
    
    public static func openPhpConfigFolder(version: String) {
        let files = [NSURL(fileURLWithPath: "/usr/local/etc/php/\(version)/php.ini")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL]);
    }
}
