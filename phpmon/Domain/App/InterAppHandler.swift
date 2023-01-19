//
//  InterAppHandler.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/01/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class InterApp {

    public static var bindings: [Action] = []

    public static func register(_ action: Action) {
        self.bindings.append(action)
    }

    public struct Action {
        let command: String
        let action: (String) -> Void
    }

    @MainActor static func getCommands() -> [InterApp.Action] { return [
        InterApp.Action(command: "list", action: { _ in
            DomainListVC.show()
        }),
        InterApp.Action(command: "services/stop", action: { _ in
            Task { MainMenu.shared.stopValetServices() }
        }),
        InterApp.Action(command: "services/restart/all", action: { _ in
            Task { MainMenu.shared.restartValetServices() }
        }),
        InterApp.Action(command: "services/restart/nginx", action: { _ in
            Task { MainMenu.shared.restartNginx() }
        }),
        InterApp.Action(command: "services/restart/php", action: { _ in
            Task { MainMenu.shared.restartPhpFpm() }
        }),
        InterApp.Action(command: "services/restart/dnsmasq", action: { _ in
            Task { MainMenu.shared.restartDnsMasq() }
        }),
        InterApp.Action(command: "locate/config", action: { _ in
            Task { MainMenu.shared.openActiveConfigFolder() }
        }),
        InterApp.Action(command: "locate/composer", action: { _ in
            Task { MainMenu.shared.openGlobalComposerFolder() }
        }),
        InterApp.Action(command: "locate/valet", action: { _ in
            Task { MainMenu.shared.openValetConfigFolder() }
        }),
        InterApp.Action(command: "phpinfo", action: { _ in
            Task { MainMenu.shared.openPhpInfo() }
        }),
        InterApp.Action(command: "switch/php/", action: { version in
            Task { MainMenu.shared.switchToAnyPhpVersion(version) }
        })
    ]}
}
