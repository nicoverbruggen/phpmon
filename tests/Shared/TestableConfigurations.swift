//
//  TestableConfigurations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import Foundation

// swiftlint:disable colon
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
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php.rb"       : .fake(.text),
                // "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.5.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.4.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.3.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.2.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.1.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@8.0.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@7.4.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@7.3.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@7.2.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@7.1.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@7.0.rb"   : .fake(.text),
                "/opt/homebrew/Library/Taps/shivammathur/homebrew-php/Formula/php@5.6.rb"   : .fake(.text)
            ],
            shellOutput: [
                "/opt/homebrew/bin/brew --version"
                    : .instant("""
                    Homebrew 4.6.11
                    """),
                "/opt/homebrew/bin/php -v"
                    : .instant("""
                    PHP 8.4.5 (cli) (built: Aug 26 2025 13:36:28) (NTS)
                    Copyright (c) The PHP Group
                    Built by Homebrew
                    Zend Engine v4.4.12, Copyright (c) Zend Technologies
                    with Xdebug v3.4.5, Copyright (c) 2002-2025, by Derick Rethans
                    with Zend OPcache v8.4.12, Copyright (c), by Zend Technologies
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
                    : .instant("Laravel Valet 4.9.0"),
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
                "ln -sF ~/.config/valet/valet84.sock ~/.config/valet/valet.sock"
                    : .instant("OK"),
                "/opt/homebrew/bin/brew update >/dev/null && /opt/homebrew/bin/brew outdated --json --formulae"
                    : .delayed(2.0,
                """
                {
                "formulae": [
                    {
                        "name": "php",
                        "installed_versions": [
                            "8.4.5"
                        ],
                        "current_version": "8.4.11",
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
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "512M"
            ],
            preferenceOverrides: [
                .automaticBackgroundUpdateCheck: false
            ],
            phpVersions: [
                VersionNumber(major: 8, minor: 4, patch: 5),
                VersionNumber(major: 8, minor: 3, patch: 5),
                VersionNumber(major: 8, minor: 2, patch: 6),
                VersionNumber(major: 8, minor: 1, patch: 0),
                VersionNumber(major: 8, minor: 0, patch: 0),
                VersionNumber(major: 7, minor: 4, patch: 33)
            ],
            apiGetResponses: [
                url("\(Constants.Urls.UpdateCheckEndpoint.absoluteString)"): FakeWebApiResponse(
                    statusCode: 200,
                    headers: [:],
                    text: """
                    cask 'phpmon-dev' do
                        depends_on formula: 'gnu-sed'

                        version '25.08.0_1000'
                        sha256 '1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a'

                        url 'https://github.com/nicoverbruggen/phpmon/releases/download/v6.0/phpmon-dev.zip'
                        name 'PHP Monitor DEV'
                        homepage 'https://phpmon.app'

                        app 'PHP Monitor DEV.app', target: "PHP Monitor DEV.app"
                    end
                    """,
                    duration: 0.5
                )
            ],
            apiPostResponses: [:]
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
// swiftlint:enable colon

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
