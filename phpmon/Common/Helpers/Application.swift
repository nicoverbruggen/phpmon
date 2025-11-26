//
//  Editor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 07/12/2021.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

/// An application that is capable of opening a particular directory (usually of a PHP project).
/// In most cases this is going to be a code editor, but it could also be another application
/// that supports opening those directories, like a visual Git client or a terminal app.
class Application {

    enum AppType {
        case editor, ide, browser, git_gui, terminal, user_supplied
    }

    // MARK: - Container

    var container: Container

    // MARK: - Variables

    /// Name of the app. Used for display purposes and to determine `name.app` exists.
    let name: String

    /// Application type. Depending on the type, a different action might occur.
    let type: AppType

    /// The full path to the application bundle (if found)
    var path: String?

    /// Initializer. Used to detect a specific app of a specific type.
    init(_ container: Container, _ name: String, _ type: AppType) {
        self.container = container
        self.name = name
        self.type = type
        self.path = determinePath()
    }

    /**
     Attempt to open a specific string (path or URL) in the app of choice.
     (This will open the app if it isn't open yet.)
     */
    @objc public func open(arg: String) {
        Task { await container.shell.quiet("/usr/bin/open -a \"\(name)\" \"\(arg)\"") }
    }

    /**
     Attempt to see if we can locate the app bundle in one of the two default locations:
     - - First in `/Applications` (system-wide installed apps)
     - - Second in `~/Applications` (user-specific installed apps)

     If not in one of these default locations, the path will be `nil` and certain operations
     will not be possible (i.e. determining icon via path to application).
     */
    func determinePath() -> String? {
        // Check global applications
        if container.filesystem.directoryExists("/Applications/\(name).app") {
            return "/Applications/\(name).app"
        }

        // Check user applications
        if container.filesystem.directoryExists("~/Applications/\(name).app") {
            return "~/Applications/\(name).app".replacingTildeWithHomeDirectory
        }

        return nil
    }

    /** Checks if the app is installed and stores its path. */
    func isInstalled() async -> Bool {
        // Then verify it's actually installed using the shell command
        let (process, output) = try! await container.shell.attach(
            "/usr/bin/open -Ra \"\(name)\"",
            didReceiveOutput: { _, _ in },
            withTimeout: 2.0
        )

        if container.shell is TestableShell {
            // When testing, check the error output (must not be empty)
            return !output.hasError
        } else {
            // If this script does not complain, the app exists!
            return process.terminationStatus == 0
        }
    }

    /**
     Detect which apps are available to open a specific directory.
     */
    static public func detectPresetApplications(
        _ container: Container
    ) async -> [Application] {
        var detected: [Application] = []

        let detectable = [
            // Browsers (for future Open In > Browser context menu)
            Application(container, "Safari", .browser),
            Application(container, "Google Chrome", .browser),
            Application(container, "Microsoft Edge", .browser),
            Application(container, "Firefox", .browser),
            Application(container, "Brave", .browser),
            Application(container, "Arc", .browser),
            Application(container, "Zen", .browser),

            // Editors
            Application(container, "PhpStorm", .ide),
            Application(container, "WebStorm", .ide),
            Application(container, "Visual Studio Code", .editor),
            Application(container, "VSCodium", .editor),
            Application(container, "Sublime Text", .editor),

            // Git
            Application(container, "Sublime Merge", .git_gui),
            Application(container, "Tower", .git_gui),
            Application(container, "SourceTree", .git_gui),

            // Terminals
            Application(container, "iTerm", .terminal),
            Application(container, "Ghostty", .terminal)
        ]

        for app in detectable where await app.isInstalled() {
            detected.append(app)
        }

        return detected
    }
}
