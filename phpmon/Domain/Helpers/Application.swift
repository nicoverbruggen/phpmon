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
    
    enum AppType {
        case editor, browser, git_gui, terminal
    }
    
    /// Name of the app. Used for display purposes and to determine `name.app` exists.
    let name: String
    
    /// Application type. Depending on the type, a different action might occur.
    let type: AppType
    
    /// Initializer. Used to detect a specific app of a specific type.
    init(_ name: String, _ type: AppType) {
        self.name = name
        self.type = type
    }
    
    /**
     Attempt to open a specific directory in the app of choice.
     (This will open the app if it isn't open yet.)
     */
    @objc public func openDirectory(file: String) {
        return Shell.run("/usr/bin/open -a \"\(name)\" \"\(file)\"")
    }
    
    /** Checks if the app is installed. */
    func isInstalled() -> Bool {
        // If this script does not complain, the app exists!
        return Shell.user.executeSynchronously(
            "/usr/bin/open -Ra \"\(name)\"",
            requiresPath: false
        ).task.terminationStatus == 0
    }
    
    /**
     Detect which apps are available to open a specific directory.
     */
    static public func detectPresetApplications() -> [Application] {
        return [
            Application("PhpStorm", .editor),
            Application("Visual Studio Code", .editor),
            Application("Sublime Text", .editor),
            Application("Sublime Merge", .git_gui),
            Application("iTerm", .terminal)
        ].filter {
            return $0.isInstalled()
        }
    }
}
