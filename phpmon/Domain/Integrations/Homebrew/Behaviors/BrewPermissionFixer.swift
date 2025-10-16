//
//  BrewPermissionFixer.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 23/04/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import ContainerMacro

@ContainerAccess
class BrewPermissionFixer {
    var broken: [DueOwnershipFormula] = []

    /**
     Takes ownership of the /BREW_PATH/Cellar/php/x.y.z/bin folder, for all PHP versions.

     This might not be required if the user has only used that version of PHP
     with site isolation, so this method checks if it's required first.

     This is a required operation for *all* PHP versions when PHP Version Manager is running
     operations, since any installation or upgrade may prompt the installation or upgrade
     of other PHP versions, in which case the permissions need to set correctly.
     */
    public func fixPermissions() async throws {
        await determineBrokenFormulae()

        if broken.isEmpty {
            return
        }

        let appleScript = NSAppleScript(
            source: "do shell script \"\(buildBrokenFormulaeScript())\" with administrator privileges"
        )

        let eventResult: NSAppleEventDescriptor? = appleScript?
            .executeAndReturnError(nil)

        if eventResult == nil {
            throw HomebrewPermissionError(
                kind: .applescriptNilError
            )
        }

        Log.info("Ownership was taken of the folder(s) at: " + broken
            .map({ $0.path })
            .joined(separator: ", "))
    }

    /**
     Determines which formulae's permissions are broken.

     To do so, PHP Monitor resolves which directory needs to be checked and verifies
     whether the Homebrew binary directory for the given PHP version is owned by root.
     */
    private func determineBrokenFormulae() async {
        let formulae = container.phpEnvs.cachedPhpInstallations.keys

        for formula in formulae {
            let realFormula = formula == PhpEnvironments.brewPhpAlias
                ? "php"
                : "php@\(formula)"

            let binFolderOwned = isOwnedByRoot(path: "\(container.paths.optPath)/\(realFormula)/bin")
            let sbinFolderOwned = isOwnedByRoot(path: "\(container.paths.optPath)/\(realFormula)/sbin")

            if binFolderOwned || sbinFolderOwned {
                Log.warn("\(formula) is owned by root")

                if binFolderOwned {
                    broken.append(DueOwnershipFormula(
                        formula: realFormula,
                        path: "\(container.paths.optPath)/\(realFormula)/bin"
                    ))
                }

                if sbinFolderOwned {
                    broken.append(DueOwnershipFormula(
                        formula: realFormula,
                        path: "\(container.paths.optPath)/\(realFormula)/sbin"
                    ))
                }
            }
        }
    }

    /**
     Generates the appropriate AppleScript script required to restore permissions.
     This script also stops the services prior to taking ownership, which is requirement.
     */
    private func buildBrokenFormulaeScript() -> String {
        return broken
            .map { b in
                return """
                    \(container.paths.brew) services stop \(b.formula) \
                    && chown -R \(container.paths.whoami):admin \(b.path)
                    """
            }
            .joined(
                separator: " && "
            )
    }

    /**
     Checks if the directory at the path is owned by the `root` user,
     by checking the FS owner account name attribute.
     */
    private func isOwnedByRoot(path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let owner = attributes[.ownerAccountName] as? String {
                return owner == "root"
            }
        } catch {
            return true
        }

        return true
    }

    struct DueOwnershipFormula {
        let formula: String
        let path: String
    }
}
