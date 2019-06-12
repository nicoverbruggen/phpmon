//
//  Environment.swift
//  phpmon
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class Environment {
    public static func performBootChecks()
    {
        if (!Shell.execute(command: "which php").contains("/usr/local/bin/php")) {
            DispatchQueue.main.async {
                Alert.present(
                    messageText: "PHP is not correctly installed",
                    informativeText: "You must install PHP via brew. Try running `which php` in Terminal, it should return `/usr/local/bin/php`. The app will not work correctly until you resolve this issue."
                )
            }
        }
        if (!Shell.execute(command: "ls /usr/local/opt | grep php@7.3").contains("php@7.3")) {
            DispatchQueue.main.async {
                Alert.present(
                    messageText: "PHP 7.3 is not correctly installed",
                    informativeText: "PHP 7.3 alias was not found in `/usr/local/opt`. The app will not work correctly until you resolve this issue."
                )
            }
        }
        if (!Shell.execute(command: "which valet").contains("/usr/local/bin/valet")) {
            DispatchQueue.main.async {
                Alert.present(
                    messageText: "Laravel Valet is not correctly installed",
                    informativeText: "You must install Valet via brew. Try running `which valet` in Terminal, it should return `/usr/local/bin/valet`. The app will not work correctly until you resolve this issue."
                )
            }
        }
    }
}
