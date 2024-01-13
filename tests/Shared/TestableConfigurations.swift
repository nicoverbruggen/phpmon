//
//  TestableConfigurations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class TestableConfigurations {
    /** A functional, working system setup that is compatible with PHP Monitor. */
    static var working: TestableConfiguration {
        return TestableConfiguration(
            architecture: "arm64",
            filesystem: [
                "/usr/local/bin/"
                    : .fake(.directory, readOnly: true),
                "/usr/local/bin/composer"
                    : .fake(.binary),
                "/opt/homebrew/bin/brew"
                    : .fake(.binary),
                "/opt/homebrew/bin/php"
                    : .fake(.binary),
                "/opt/homebrew/bin/valet"
                    : .fake(.binary),
                "~/.config/valet/config.json"
                    : .fake(.text, """
                    {
                    "tld": "test",
                    "paths": [
                        "/Users/user/.config/valet/Sites",
                        "/Users/user/Sites"
                    ],
                        "loopback": "127.0.0.1"
                    }
                    """),
            ],
            shellOutput: [
                "/opt/homebrew/bin/brew --version"
                    : .instant("""
                    Homebrew 4.0.17-93-gb0dc84b
                    Homebrew/homebrew-core (git revision 4113c35d80d; last commit 2023-04-06)
                    Homebrew/homebrew-cask (git revision bcd8ecb74c; last commit 2023-04-06)
                    """),
                "/opt/homebrew/bin/php -v"
                    : .instant("""
                    PHP 8.2.6 (cli) (built: May 11 2023 12:51:38) (NTS)
                    Copyright (c) The PHP Group
                    Zend Engine v4.2.6, Copyright (c) Zend Technologies
                    with Zend OPcache v8.2.6, Copyright (c), by Zend Technologies
                    with Xdebug v3.2.0, Copyright (c) 2002-2022, by Derick Rethans
                    """),
                "sysctl -n sysctl.proc_translated"
                    : .instant("0"),
                "id -un"
                    : .instant("user"),
                "which node"
                    : .instant("/opt/homebrew/bin/node"),
                "sudo /opt/homebrew/bin/brew services info dnsmasq --json"
                    : .delayed(0.2, """
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
                    """),
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
                "chmod +x /Users/nicoverbruggen/.config/phpmon/bin/pm82"
                    : .instant(""),
                "mkdir -p ~/.config/phpmon"
                    : .instant(""),
                "mkdir -p ~/.config/phpmon/bin"
                    : .instant(""),
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
                "/opt/homebrew/bin/brew info php --json"
                    : .instant(ShellStrings.shared.brewJson),
                "sudo /opt/homebrew/bin/brew services info --all --json"
                    : .instant(ShellStrings.shared.brewServicesAsRoot),
                "/opt/homebrew/bin/brew services info --all --json"
                    : .instant(ShellStrings.shared.brewServicesAsUser),
                "curl -s --max-time 10 '\(Constants.Urls.DevBuildCaskFile.absoluteString)'"
                    : .delayed(0.5, """
                cask 'phpmon-dev' do
                    depends_on formula: 'gnu-sed'

                    version '6.0.0_1000'
                    sha256 '1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a'

                    url 'https://github.com/nicoverbruggen/phpmon/releases/download/v6.0/phpmon-dev.zip'
                    name 'PHP Monitor DEV'
                    homepage 'https://phpmon.app'

                    app 'PHP Monitor DEV.app', target: "PHP Monitor DEV.app"
                end
                """),
                "/opt/homebrew/bin/brew unlink php"
                    : .delayed(0.2, "OK"),
                "/opt/homebrew/bin/brew unlink php@8.2"
                    : .delayed(0.2, "OK"),
                "/opt/homebrew/bin/brew link php --overwrite --force"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services stop php"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services start php"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services stop nginx"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services start nginx"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services stop dnsmasq"
                    : .delayed(0.2, "OK"),
                "sudo /opt/homebrew/bin/brew services start dnsmasq"
                    : .delayed(0.2, "OK"),
                "ln -sF ~/.config/valet/valet82.sock ~/.config/valet/valet.sock"
                    : .instant("OK"),
                "/opt/homebrew/bin/brew update >/dev/null && /opt/homebrew/bin/brew outdated --json --formulae": .delayed(2.0, """
                {
                "formulae": [
                    {
                        "name": "php",
                        "installed_versions": [
                            "8.2.6"
                        ],
                        "current_version": "8.2.11",
                        "pinned": false,
                        "pinned_version": null
                    }
                ],
                "casks": []
                }
                """)
            ],
            commandOutput: [
                "/opt/homebrew/bin/php -r echo ini_get('memory_limit');": "512M",
                "/opt/homebrew/bin/php -r echo ini_get('upload_max_filesize');": "512M",
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "512M",
            ],
            preferenceOverrides: [
                .automaticBackgroundUpdateCheck: false
            ],
            phpVersions: [
                VersionNumber(major: 8, minor: 2, patch: 6),
                VersionNumber(major: 8, minor: 1, patch: 0),
                VersionNumber(major: 8, minor: 0, patch: 0),
                VersionNumber(major: 7, minor: 4, patch: 33)
            ]
        )
    }

    /** A functional, working system setup (but without Valet). */
    static var workingWithoutValet: TestableConfiguration {
        var configuration = TestableConfigurations.working
        configuration.filesystem["/opt/homebrew/bin/valet"] = nil
        configuration.filesystem["~/.config/valet/config.json"] = nil
        return configuration
    }
}

class ShellStrings {
    static var shared = ShellStrings()

    var brewJson: String = ""
    var brewServicesAsUser: String = ""
    var brewServicesAsRoot: String = ""

    init() {
        self.brewJson = loadFile("brew-formula")
        self.brewServicesAsUser = loadFile("brew-services-normal")
        self.brewServicesAsRoot = loadFile("brew-services-sudo")
    }

    private func loadFile(_ fileName: String, fileExtension: String = "json") -> String {
        let bundle = Bundle(for: type(of: self))
        return try! String(contentsOf: bundle.url(
            forResource: fileName,
            withExtension: fileExtension
        )!, encoding: .utf8)
    }
}
