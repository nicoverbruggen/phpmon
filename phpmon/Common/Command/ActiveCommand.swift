//
//  ActiveCommand.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

var Command: CommandProtocol {
    return ActiveCommand.shared
}

class ActiveCommand {
    static var shared: CommandProtocol = RealCommand()

    public static func useTestable(_ output: [String: String]) {
        Self.shared = TestableCommand(commands: output)
    }

    public static func useSystem() {
        Self.shared = RealCommand()
    }
}
