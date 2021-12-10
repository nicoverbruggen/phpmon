//
//  Editor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/// An application that is capable of opening a particular directory (usually of a PHP project).
/// In most cases this is going to be a code editor, but it could also be another application
/// that supports opening those directories, like a visual Git client or a terminal app.
class Application {
    
    /// Name of the app. Used for display purposes.
    let name: String
    
    /// Paths to check whether the application is actually installed.
    /// If the app finds any of these, the app is considered installed.
    let pathsToVerifyInstalled: [String]
    
    /// Path to the binary that actually opens the directory.
    let pathToBinary: String
    
    /// Instruction that needs to be followed in order to ensure that the app can open with this editor.
    var missingBinaryInstruction: String? = nil
    
    /// Callback that is executed to open a particular folder.
    /// Must open the directory in the requested app, usually by using `pathToBinary`.
    @objc let openCallback: (String) -> Void
    
    /**
     - Parameter name: Name of the application.
     - Parameter installPath: Files to verify, if any file exists here the app is considered present on the system.
     - Parameter binaryPath: Additional file that is used to open a specific path.
     - Parameter open: Callback used to open a specific directory in the editor in question.
     - Parameter instruction: Instruction for end user that needs to be followed in order to ensure the `binaryPath exists.
     */
    init(name: String, installPaths: [String], binaryPath: String, open: @escaping ((String) -> Void), instruction: String? = nil) {
        self.name = name
        self.pathsToVerifyInstalled = installPaths.map({ path in
            return path.replacingOccurrences(of: " ", with: "\\ ")
        })
        self.pathToBinary = binaryPath.replacingOccurrences(of: " ", with: "\\ ")
        self.openCallback = open
        self.missingBinaryInstruction = instruction
    }
    
    /**
     Attempt to open a specific directory in the editor of choice.
     This will open the editor if it isn't open yet.
     */
    @objc public func openDirectory(file: String) {
        self.openCallback(file)
    }
    
    /** Checks if the app is installed. */
    func isInstalled() -> Bool {
        // TODO: Alternative way to detect if an app is installed:
        // mdfind "kMDItemKind == 'Application'" | grep AppName.app
        // This will return the path to the application. Worth a refactor?
        self.pathsToVerifyInstalled.map({ path in
            Shell.fileExists(path)
        }).contains(true)
    }
    
    /** Checks if the correct binary required to open directories and/or files exists. */
    func hasBinary() -> Bool {
        return Shell.fileExists(self.pathToBinary)
    }
    
    /**
     Detect which apps are available to open a specific directory.
     */
    static public func detectPresetApplications() -> [Application] {
        return [
            Application(
                name: "PhpStorm",
                installPaths: [
                    "/Applications/PhpStorm.app/Contents/Info.plist",
                    "/usr/local/bin/pstorm"
                ],
                binaryPath: "/usr/local/bin/pstorm",
                open: { path in
                    Shell.run("/usr/local/bin/pstorm \(path)")
                },
                instruction: "editors.pstorm_binary_not_linked.desc".localized
            ),
            Application(
                name: "PhpStorm (via Toolbox)",
                installPaths: [
                    "~/Applications/JetBrains Toolbox/PhpStorm.app/Contents/Info.plist",
                    "/usr/local/bin/phpstorm"
                ],
                binaryPath: "/usr/local/bin/phpstorm",
                open: { path in
                    Shell.run("/usr/local/bin/phpstorm \(path)")
                },
                instruction: "editors.phpstorm_binary_not_linked.desc".localized
            ),
            Application(
                name: "Visual Studio Code",
                installPaths: [
                    "/Applications/Visual Studio Code.app/Contents/Info.plist",
                    "/usr/local/bin/code"
                ],
                binaryPath: "/usr/local/bin/code",
                open: { path in
                    Shell.run("/usr/local/bin/code \(path)")
                },
                instruction: "editors.code_binary_not_linked.desc".localized
            ),
            Application(
                name: "Sublime Text",
                installPaths: ["/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"],
                binaryPath: "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl",
                open: { path in
                    Shell.run("/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl \(path)")
                }
            ),
            Application(
                name: "Sublime Merge",
                installPaths: ["/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge"],
                binaryPath: "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge",
                open: { path in
                    Shell.run("/Applications/Sublime\\ Merge.app/Contents/SharedSupport/bin/smerge \(path)")
                }
            ),
            Application(
                name: "iTerm",
                installPaths: ["/Applications/iTerm.app/Contents/Info.plist"],
                binaryPath: "/Applications/iTerm.app/Contents/Info.plist",
                open: { path in
                    Shell.run("open -a iTerm \(path)")
                }
            )
        ].filter { return $0.isInstalled() }
    }
}
