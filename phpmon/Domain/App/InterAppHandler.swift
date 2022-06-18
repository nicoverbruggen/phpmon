//
//  InterAppHandler.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 28/01/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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

    static func getCommands() -> [InterApp.Action] { return [
        InterApp.Action(command: "list", action: { _ in
            DomainListVC.show()
        }),
        InterApp.Action(command: "services/stop", action: { _ in
            MainMenu.shared.stopValetServices()
        }),
        InterApp.Action(command: "services/restart/all", action: { _ in
            MainMenu.shared.restartValetServices()
        }),
        InterApp.Action(command: "services/restart/nginx", action: { _ in
            MainMenu.shared.restartNginx()
        }),
        InterApp.Action(command: "services/restart/php", action: { _ in
            MainMenu.shared.restartPhpFpm()
        }),
        InterApp.Action(command: "services/restart/dnsmasq", action: { _ in
            MainMenu.shared.restartDnsMasq()
        }),
        InterApp.Action(command: "locate/config", action: { _ in
            MainMenu.shared.openActiveConfigFolder()
        }),
        InterApp.Action(command: "locate/composer", action: { _ in
            MainMenu.shared.openGlobalComposerFolder()
        }),
        InterApp.Action(command: "locate/valet", action: { _ in
            MainMenu.shared.openValetConfigFolder()
        }),
        InterApp.Action(command: "phpinfo", action: { _ in
            MainMenu.shared.openPhpInfo()
        }),
        InterApp.Action(command: "switch/php/", action: { version in
            if PhpEnv.shared.availablePhpVersions.contains(version) {
                MainMenu.shared.switchToPhpVersion(version)
            } else {
                DispatchQueue.main.async {
                    BetterAlert().withInformation(
                        title: "alert.php_switch_unavailable.title".localized,
                        subtitle: "alert.php_switch_unavailable.subtitle".localized(version)
                    ).withPrimary(
                        text: "alert.php_switch_unavailable.ok".localized
                    ).show()
                }
            }
        })
    ]}

}
