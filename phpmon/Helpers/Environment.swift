//
//  Environment.swift
//  phpmon
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class Environment {
    
    public static func presentAlertOnMainThreadIf(_ condition: Bool, messageText: String, informativeText: String)
    {
        if (condition) {
            DispatchQueue.main.async {
                Alert.present(
                    messageText: messageText,
                    informativeText: informativeText
                )
            }
            // TODO: Quit the app in any of these scenarios?
        }
    }
    
    public static func performBootChecks()
    {
        self.presentAlertOnMainThreadIf(
            !Shell.execute(command: "which php").contains("/usr/local/bin/php"),
            messageText: "PHP is not correctly installed",
            informativeText: "You must install PHP via brew. Try running `which php` in Terminal, it should return `/usr/local/bin/php`. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.execute(command: "ls /usr/local/opt | grep php@7.3").contains("php@7.3"),
            messageText: "PHP 7.3 is not correctly installed",
            informativeText: "PHP 7.3 alias was not found in `/usr/local/opt`. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.execute(command: "which valet").contains("/usr/local/bin/valet"),
            messageText: "Laravel Valet is not correctly installed",
            informativeText: "You must install Valet via brew. Try running `which valet` in Terminal, it should return `/usr/local/bin/valet`. The app will not work correctly until you resolve this issue."
        )
        
        // TODO: Add check for /private/etc/sudoers.d/brew || /private/etc/sudoers.d/valet
    }
}
