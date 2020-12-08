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
            messageText:        "startup.errors.php_binary.title".localized,
            informativeText:    "startup.errors.php_binary_desc".localized,
            breaking:           true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("ls /usr/local/opt | grep php").contains("php"),
            messageText:        "startup.errors.php_opt.title".localized,
            informativeText:    "startup.errors.php_opt.desc".localized,
            breaking:           true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("which valet").contains("/usr/local/bin/valet"),
            messageText:        "startup.errors.valet_executable.title".localized,
            informativeText:    "startup.errors.valet_executable.desc".localized,
            breaking:           true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("cat /private/etc/sudoers.d/brew").contains("/usr/local/bin/brew"),
            messageText:        "startup.errors.sudoers_brew.title".localized,
            informativeText:    "startup.errors.sudoers_brew.desc".localized,
            breaking:           true
        )
        
        self.performEnvironmentCheck(
            !Shell.user.pipe("cat /private/etc/sudoers.d/valet").contains("/usr/local/bin/valet"),
            messageText:        "startup.errors.sudoers_valet.title".localized,
            informativeText:    "startup.errors.sudoers_valet.desc".localized,
            breaking:           true
        )
        
        let services = Shell.user.pipe("brew services list | grep php")
        self.performEnvironmentCheck(
            (services.countInstances(of: "started") > 1),
            messageText:        "startup.errors.services.title".localized,
            informativeText:    "startup.errors.services.desc".localized,
            breaking:           false
        )
        
        if (!self.failed) {
            self.determineBrewAliasVersion()
            success()
        }
    }
    
    /**
     * In order to avoid having to hard-code which version of PHP is aliased to what specific subversion,
     * PHP Monitor now determines the alias by checking the user's system.
     */
    private func determineBrewAliasVersion()
    {
        print("PHP Monitor has determined the application has successfully passed all checks.")
        print("Determining which version of PHP is aliased to `php` via Homebrew...")
        
        let brewPhpAlias = Shell.user.pipe("brew info php --json");
        
        App.shared.brewPhpPackage = try! JSONDecoder().decode(
            [HomebrewPackage].self,
            from: brewPhpAlias.data(using: .utf8)!
        ).first!
        
        print("When on your system, the `php` formula means version \(App.shared.brewPhpVersion)!")
    }
    
    /**
     * Perform an environment check. Will cause the application to terminate, if `breaking` is set to true.
     *
     * - Parameter condition: Fail condition to check for; if this returns `true`, the alert will be shown
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
