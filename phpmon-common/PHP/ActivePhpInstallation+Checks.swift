//
//  ActivePhpInstallation.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

extension ActivePhpInstallation {
    
    /**
     It is always possible that the system configuration for PHP-FPM has not been set up for Valet.
     This can occur when a user manually installs a new PHP version, but does not run `valet install`.
     In that case, we should alert the user!
     
     - Important: The underlying check is `checkPhpFpmStatus`, which can be run multiple times.
     This method actively presents a modal if said checks fails, so don't call this method too many times.
     */
    public func notifyAboutBrokenPhpFpm() {
        if !self.checkPhpFpmStatus() {
            DispatchQueue.main.async {
                Alert.notify(
                    message: "alert.php_fpm_broken.title".localized,
                    info: "alert.php_fpm_broken.info".localized,
                    style: .critical
                )
            }
        }
    }
    
}
