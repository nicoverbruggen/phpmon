//
//  Environment.swift
//  phpmon
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class BootChecks {
    
    public static func perform()
    {
        self.presentAlertOnMainThreadIf(
            !Shell.shared.pipe("which php").contains("/usr/local/bin/php"),
            messageText: "PHP is not correctly installed",
            informativeText: "You must install PHP via brew. Try running `which php` in Terminal, it should return `/usr/local/bin/php`. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.shared.pipe("ls /usr/local/opt | grep php@7.3").contains("php@7.3"),
            messageText: "PHP 7.3 is not correctly installed",
            informativeText: "PHP 7.3 alias was not found in `/usr/local/opt`. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.shared.pipe("which valet").contains("/usr/local/bin/valet"),
            messageText: "Laravel Valet is not correctly installed",
            informativeText: "You must install Valet via brew. Try running `which valet` in Terminal, it should return `/usr/local/bin/valet`. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.shared.pipe("cat /private/etc/sudoers.d/brew").contains("/usr/local/bin/brew"),
            messageText: "Brew has not been added to sudoers.d",
            informativeText: "You must run `sudo valet trust` to ensure Valet can start and stop services without having to use sudo every time. The app will not work correctly until you resolve this issue."
        )
        
        self.presentAlertOnMainThreadIf(
            !Shell.shared.pipe("cat /private/etc/sudoers.d/valet").contains("/usr/local/bin/valet"),
            messageText: "Valet has not been added to sudoers.d",
            informativeText: "You must run `sudo valet trust` to ensure Valet can start and stop services without having to use sudo every time. The app will not work correctly until you resolve this issue."
        )
    }
    
    private static func presentAlertOnMainThreadIf(
        _ condition: Bool,
        messageText: String,
        informativeText: String
    )
    {
        if (condition) {
            DispatchQueue.main.async {
                Alert.present(
                    messageText: messageText,
                    informativeText: informativeText
                )
            }
        }
    }
}
