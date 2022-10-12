//
//  TestableConfigurations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

struct TestableConfiguration {
    let architecture: String
    let filesystem: [String: FakeFile]
    let shellOutput: [String: BatchFakeShellOutput]

    func apply() {
        ActiveShell.useTestable(shellOutput)
        ActiveFileSystem.useTestable(filesystem)
    }
}

// swiftlint:disable colon trailing_comma
class TestableConfigurations {
    static var broken: TestableConfiguration {
        return TestableConfiguration(
            architecture: "arm64",
            filesystem: [:],
            shellOutput: [
                "id -un"                            : .instant("username"),
                "php -v"                            : .instant(""),
                "ls /opt/homebrew/opt | grep php"   : .instant(""),
            ]
        )
    }

    // TODO: All expected, correct Terminal responses
    static var working: TestableConfiguration {
        return TestableConfiguration(
            architecture: "arm64",
            filesystem: [
                "/opt/homebrew/brew"
                    : .fake(.binary),
                "/opt/homebrew/opt/php"
                    : .fake(.symlink, "/opt/homebrew/Cellar/php/8.1.10_1"),
                "/opt/homebrew/Cellar/php/8.1.10_1"
                    : .fake(.directory),
                "/opt/homebrew/Cellar/php/8.1.10_1/bin/php"
                    : .fake(.binary),
                "/opt/homebrew/Cellar/php/8.1.10_1/bin/php-config"
                    : .fake(.binary)
            ],
            shellOutput: [
                "sysctl -n sysctl.proc_translated"
                    : .instant("0"),
                "id -un"
                    : .instant("nicoverbruggen"),
                "which node"
                    : .instant("/opt/homebrew/bin/node"),
                "php -v"
                : .instant(ShellStrings.phpVersion),
                "ls /opt/homebrew/opt | grep php"
                    : .instant("php"),
                "ls /opt/homebrew/opt | grep php@"
                    : .instant("php@8.1"),
                "sudo /opt/homebrew/bin/brew services info nginx --json"
                    : .delayed(0.2, ShellStrings.nginxJson),
                "cat /private/etc/sudoers.d/brew"
                    : .instant("""
                    Cmnd_Alias BREW = /opt/homebrew/bin/brew *
                    %admin ALL=(root) NOPASSWD:SETENV: BREW
                    """),
                "cat /private/etc/sudoers.d/valet"
                    : .instant("""
                    Cmnd_Alias VALET = /opt/homebrew/bin/valet *
                    %admin ALL=(root) NOPASSWD:SETENV: VALET
                    """),
                "valet --version"
                    : .instant("Laravel Valet 3.1.11"),
                "/opt/homebrew/bin/brew tap"
                    : .instant("""
                    homebrew/cask
                    homebrew/core
                    homebrew/services
                    nicoverbruggen/cask
                    shivammathur/php
                    """),
                "chmod +x /Users/nicoverbruggen/.config/phpmon/bin/pm81"
                    : .instant(""),
                "mkdir -p ~/.config/phpmon"
                    : .instant(""),
                "mkdir -p ~/.config/phpmon/bin"
                    : .instant(""),
                "/opt/homebrew/bin/brew info php --json"
                    : .instant(ShellStrings.brewJson),
                "brew info shivammathur/php/php --json"
                    : .instant("Error: No available formula with the name \"shivammathur/php/php\"."),
                "/usr/bin/open -Ra \"PhpStorm\""
                    : .instant("Unable to find application named 'PhpStorm'", .stdErr),
                "/usr/bin/open -Ra \"Visual Studio Code\""
                    : .instant("Unable to find application named 'Visual Studio Code'", .stdErr),
                "/usr/bin/open -Ra \"Sublime Text\""
                    : .instant("Unable to find application named 'Sublime Text'", .stdErr),
                "/usr/bin/open -Ra \"Sublime Merge\""
                    : .instant("Unable to find application named 'Sublime Merge'", .stdErr),
                "/usr/bin/open -Ra \"iTerm\""
                    : .instant("Unable to find application named 'iTerm'", .stdErr),
            ]
        )
    }
}

struct ShellStrings {

    static let phpVersion = """
       PHP 8.1.10 (cli) (built: Sep  3 2022 12:09:27) (NTS)
       Copyright (c) The PHP Group
       Zend Engine v4.1.10, Copyright (c) Zend Technologies
       with Zend OPcache v8.1.10, Copyright (c), by Zend Technologies
    """

    static let nginxJson = """
        [
            {
            "name": "nginx",
            "service_name": "homebrew.mxcl.nginx",
            "running": true,
            "loaded": true,
            "schedulable": false,
            "pid": 133,
            "exit_code": 0,
            "user": "root",
            "status": "started",
            "file": "/Library/LaunchDaemons/homebrew.mxcl.nginx.plist",
            "command": "/opt/homebrew/opt/nginx/bin/nginx -g daemon off;",
            "working_dir": "/opt/homebrew",
            "root_dir": null,
            "log_path": null,
            "error_log_path": null,
            "interval": null,
            "cron": null
            }
        ]
    """

    static let brewJson: String = {
        return try! String(contentsOf: Bundle.main.url(
            forResource: "brew-formula",
            withExtension: "json"
        )!, encoding: .utf8)
    }()
}
