//
//  Services.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class Services {
    public static func mysqlIsRunning() -> Bool {
        let running = Shell.execute(command: "launchctl list | grep homebrew.mxcl.mysql")
        if (running != "") {
            return true
        }
        return false
    }
    
    public static func nginxIsRunning() -> Bool {
        let running = Shell.execute(command: "launchctl list | grep homebrew.mxcl.nginx")
        if (running != "") {
            return true
        }
        return false
    }
    
    public static func detectPhpVersions() -> [String] {
        let files = Shell.execute(command: "ls /usr/local/opt | grep php@")
        var versions = files!.components(separatedBy: "\n")
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
            _ = Shell.execute(command: "brew unlink php@\(version)")
        }
        if (availableVersions.contains("7.3")) {
            _ = Shell.execute(command: "brew link php@7.3")
            _ = Shell.execute(command: "valet use php@\(version)")
        }
    }
}
