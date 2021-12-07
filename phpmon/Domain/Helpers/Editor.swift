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
/// that supports opening those directories, like a visual Git client.
class Editor {
    
    /// Name of the editor. Used for display purposes.
    let name: String
    
    /// Path to check whether the application is actually installed.
    /// This was previously called `path` but the new variable name is a bit more clear.
    /// To be clear, this is *not* the path to the actual binary!
    let pathToVerifyInstalled: String
    
    /// Callback that is executed to open a particular folder. Can be different from the installation path or the procedure required to determine whether the application is installed.
    @objc let openCallback: (String) -> Void
    
    /**
     - Parameter name: Name of the editor.
     - Parameter path: File to verify, if this file exists here the app is considered present on the system.
     - Parameter open: Callback used to open a specific directory in the editor in question.
     */
    init(name: String, path: String, open: @escaping ((String) -> Void)) {
        self.name = name
        self.pathToVerifyInstalled = path.replacingOccurrences(of: " ", with: "\\ ")
        self.openCallback = open
    }
    
    /**
     Attempt to open a specific directory in the editor of choice. This will open the editor if it isn't open yet.
     */
    @objc public func openDirectory(file: String) {
        self.openCallback(file)
    }
    
    /**
     Detect which "editors" are available to open a specific directory.
     */
    static public func detect() -> [Editor] {
        return [
            Editor(
                name: "PhpStorm",
                path: "/Applications/PhpStorm.app/Contents/Info.plist",
                open: { path in
                    Shell.run("open -a /Applications/PhpStorm.app \(path)")
                }
            ),
            Editor(
                name: "PhpStorm (via Toolbox)",
                path: "~/Applications/JetBrains Toolbox/PhpStorm.app/Contents/Info.plist",
                open: { path in
                    Shell.run("open -a ~/Applications/JetBrains\\ Toolbox/PhpStorm.app \(path)")
                }
            ),
            Editor(
                name: "Visual Studio Code",
                path: "/usr/local/bin/code",
                open: { path in
                    Shell.run("/usr/local/bin/code \(path)")
                }
            ),
            Editor(
                name: "Sublime Text",
                path: "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl",
                open: { path in
                    Shell.run("/Applications/Sublime\\ Text.app/Contents/SharedSupport/bin/subl \(path)")
                }
            ),
            Editor(
                name: "Sublime Merge",
                path: "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/smerge",
                open: { path in
                    Shell.run("/Applications/Sublime\\ Merge.app/Contents/SharedSupport/bin/smerge \(path)")
                }
            )
        ].filter { editor in
            Shell.fileExists(editor.pathToVerifyInstalled)
        }
    }
}
