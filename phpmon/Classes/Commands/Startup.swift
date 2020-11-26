//
//  Environment.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Foundation

class Startup {
    
    public var failed : Bool = false
    public var failureCallback = {}
    
    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     - Parameter success: Callback that is fired if the application can proceed with launch
     - Parameter failure: Callback that is fired if the application must retry launch
     */
    public func checkEnvironment(success: () -> Void, failure: @escaping () -> Void)
    {
        self.failureCallback = failure
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("which php").contains("/usr/local/bin/php"),
            messageText: "PHP is not correctly installed",
            informativeText: "You must install PHP via brew. Try running `which php` in Terminal, it should return `/usr/local/bin/php`. The app will not work correctly until you resolve this issue. (Usually `brew link php` resolves this issue.)",
            breaking: true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("ls /usr/local/opt | grep php@7.4").contains("php@7.4"),
            messageText: "PHP 7.4 is not correctly installed",
            informativeText: "PHP 7.4 alias was not found in `/usr/local/opt`. The app will not work correctly until you resolve this issue. If you already have the `php` formula installed, you may need to run `brew install php@7.4` in order for PHP Monitor to detect this installation.",
            breaking: true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("which valet").contains("/usr/local/bin/valet"),
            messageText: "Laravel Valet is not correctly installed",
            informativeText: "You must install Valet with composer. Try running `which valet` in Terminal, it should return `/usr/local/bin/valet`. The app will not work correctly until you resolve this issue.",
            breaking: true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("cat /private/etc/sudoers.d/brew").contains("/usr/local/bin/brew"),
            messageText: "Brew has not been added to sudoers.d",
            informativeText: "You must run `sudo valet trust` to ensure Valet can start and stop services without having to use sudo every time. The app will not work correctly until you resolve this issue.",
            breaking: true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("cat /private/etc/sudoers.d/valet").contains("/usr/local/bin/valet"),
            messageText: "Valet has not been added to sudoers.d",
            informativeText: "You must run `sudo valet trust` to ensure Valet can start and stop services without having to use sudo every time. The app will not work correctly until you resolve this issue.",
            breaking: true
        )
        
        let services = Shell.user.pipe("brew services list | grep php")
        self.performEnvironmentCheck(
            (services.countInstances(of: "started") > 1),
            messageText: "Multiple PHP services are active",
            informativeText: "This can cause php-fpm to serve a more recent version of PHP than the one you'd like to see active. Please terminate all extra PHP processes." +
            "\n\nThe easiest solution is to choose the option 'Force load latest PHP version' in the menu bar." +
            "\n\nAlternatively, you can fix this manually. You can do this by running `brew services list` and running `sudo brew services stop php@7.3` (and use the version that applies)." +
            "\n\nPHP Monitor usually handles the starting and stopping of these services, so once the correct version is the only PHP version running you should not have any issues. It is recommended to restart PHP Monitor once you have resolved this issue." +
            "\n\nFor more information about this issue, please see the README.md file in the repository on GitHub.",
            breaking: false
        )
        
        let brewPhpAlias = Shell.user.pipe("brew info php --json");
        print(brewPhpAlias)
        
        if (!self.failed) {
            success()
        }
    }
    
    /**
     * Perform an environment check. Will cause the application to terminate, if `breaking` is set to true.
     *
     * - Parameter condition: Condition to check for
     * - Parameter messageText: Short description of what is wrong
     * - Parameter informativeText: Expanded description of the environment check that failed
     * - Parameter breaking: If the application should terminate afterwards
     */
    private func performEnvironmentCheck(
        _ condition: Bool,
        messageText: String,
        informativeText: String,
        breaking: Bool
    )
    {
        if (condition) {
            // Only breaking issues will cause the notification
            if (breaking) {
                self.failed = true
            }
            DispatchQueue.main.async {
                // Present the information to the user
                _ = Alert.present(
                    messageText: messageText,
                    informativeText: informativeText
                )
                // Only breaking issues will throw the extra retry modal
                if (breaking) {
                     self.failureCallback()
                }
            }
        }
    }
}
