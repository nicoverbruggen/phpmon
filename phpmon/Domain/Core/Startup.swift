//
//  Environment.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Startup {
    
    public var failed : Bool = false
    public var failureCallback = {}
    
    /**
     Checks the user's environment and checks if PHP Monitor can be used properly.
     This checks if PHP is installed, Valet is running, the appropriate permissions are set, and more.
     
     - Parameter success: Callback that is fired if the application can proceed with launch
     - Parameter failure: Callback that is fired if the application must retry launch
     */
    func checkEnvironment(success: () -> Void, failure: @escaping () -> Void)
    {
        failureCallback = failure
        
        performEnvironmentCheck(
            !Shell.fileExists("\(Paths.binPath)/php"),
            messageText:        "startup.errors.php_binary.title".localized,
            informativeText:    "startup.errors.php_binary.desc".localized,
            breaking:           true
        )
        
        performEnvironmentCheck(
            !Shell.pipe("ls \(Paths.optPath) | grep php").contains("php"),
            messageText:        "startup.errors.php_opt.title".localized,
            informativeText:    "startup.errors.php_opt.desc".localized,
            breaking:           true
        )
        
        performEnvironmentCheck(
            // Check for Valet; it can be symlinked or in .composer/vendor/bin
            !(Shell.fileExists("/usr/local/bin/valet")
                || Shell.fileExists("/opt/homebrew/bin/valet")
                || Shell.fileExists("~/.composer/vendor/bin/valet")
            ),
            messageText:        "startup.errors.valet_executable.title".localized,
            informativeText:    "startup.errors.valet_executable.desc".localized,
            breaking:           true
        )
        
        Valet.shared.version = VersionExtractor.from(valet("--version"))
        performEnvironmentCheck(
            Valet.shared.version == nil,
            messageText:        "startup.errors.valet_version_unknown.title".localized,
            informativeText:    "startup.errors.valet_version_unknown.desc".localized(
                "prefs.auto_composer_update_title".localized
            ),
            breaking:           true
        )
        
        performEnvironmentCheck(
            HomebrewDiagnostics.cannotLoadService(),
            messageText:        "startup.errors.services_json_error.title".localized,
            informativeText:    "startup.errors.services_json_error.desc".localized,
            breaking:           true
        )
        
        performEnvironmentCheck(
            !Shell.pipe("cat /private/etc/sudoers.d/brew").contains("\(Paths.binPath)/brew"),
            messageText:        "startup.errors.sudoers_brew.title".localized,
            informativeText:    "startup.errors.sudoers_brew.desc".localized,
            breaking:           true
        )
        
        performEnvironmentCheck(
            // Check for Valet; it MUST be symlinked thanks to sudoers
            !(Shell.pipe("cat /private/etc/sudoers.d/valet").contains("/usr/local/bin/valet")
                || Shell.pipe("cat /private/etc/sudoers.d/valet").contains("/opt/homebrew/bin/valet")
            ),
            messageText:        "startup.errors.sudoers_valet.title".localized,
            informativeText:    "startup.errors.sudoers_valet.desc".localized,
            breaking:           true
        )
        
        let services = Shell.pipe("\(Paths.brew) services list | grep php")
        performEnvironmentCheck(
            (services.countInstances(of: "started") > 1),
            messageText:        "startup.errors.services.title".localized,
            informativeText:    "startup.errors.services.desc".localized,
            breaking:           false
        )
        
        if (!failed) {
            initializeSwitcher()
            Log.info("PHP Monitor has determined the application has successfully passed all checks.")
            success()
        }
    }
    
    /**
     Because the Switcher requires various environment guarantees, the switcher is only
     initialized when it is done working.
     */
    private func initializeSwitcher() {
        DispatchQueue.main.async {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.initializeSwitcher()
        }
    }

    /**
     Perform an environment check. Will cause the application to terminate, if `breaking` is set to true.
     
     - Parameter condition: Fail condition to check for; if this returns `true`, the alert will be shown
     - Parameter messageText: Short description of what is wrong
     - Parameter informativeText: Expanded description of the environment check that failed
     - Parameter breaking: If the application should terminate afterwards
     */
    private func performEnvironmentCheck(
        _ condition: Bool,
        messageText: String,
        informativeText: String,
        breaking: Bool
    ) {
        if (!condition) { return }
        
        failed = breaking

        DispatchQueue.main.async { [self] in
            // Present the information to the user
            Alert.notify(
                message: messageText,
                info: informativeText,
                style: breaking ? .critical : .warning
            )
            // Only breaking issues will throw the extra retry modal
            breaking ? failureCallback() : ()
        }
    }
    
}
