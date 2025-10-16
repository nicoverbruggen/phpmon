//
//  PhpConfigChecker.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 24/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import ContainerMacro

struct FileExistenceCheck {
    let condition: (() -> Bool)?
    let path: String
}

@ContainerAccess
class PhpConfigChecker {
    public static var shared = PhpConfigChecker(App.shared.container)

    var missing: [String] = []

    public func check() {
        missing = []

        let shouldExist: [FileExistenceCheck] = [
            FileExistenceCheck(condition: nil, path: "php.ini"),
            FileExistenceCheck(condition: nil, path: "php-fpm.conf"),
            FileExistenceCheck(condition: { Valet.installed }, path: "php-fpm.d/valet-fpm.conf")
        ]

        for version in container.phpEnvs.availablePhpVersions {
            for file in shouldExist {
                // Early exit in case our condition is not met
                if file.condition != nil && file.condition!() == false {
                    continue
                }

                // Do the check
                let fullFilePath = container.paths.etcPath.appending("/php/\(version)/\(file.path)")
                if !container.filesystem.fileExists(fullFilePath) {
                    missing.append(fullFilePath)
                }
            }
        }

        if !missing.isEmpty {
            Log.warn("The following config file(s) were missing: \(missing)")
        }
    }
}
