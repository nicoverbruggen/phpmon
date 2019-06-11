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
}
