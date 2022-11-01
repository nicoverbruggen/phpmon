//
//  TestableConfigurations.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/10/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
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
                "/opt/homebrew/opt/php"
                    : .fake(.symlink, "/opt/homebrew/Cellar/php/8.1.10_1"),
                "/opt/homebrew/opt/php@8.1/bin/php"
                    : .fake(.symlink, "/opt/homebrew/Cellar/php/8.1.10_1/bin/php"),
                "/opt/homebrew/Cellar/php/8.1.10_1/bin/php"
                    : .fake(.binary),
                "/opt/homebrew/Cellar/php/8.1.10_1/bin/php-config"
                    : .fake(.binary),
                "/opt/homebrew/etc/php/8.1/php-fpm.d/www.conf"
                    : .fake(.text),
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
                "/opt/homebrew/etc/php/8.1/php-fpm.d/valet-fpm.conf"
                    : .fake(.text),
            ],
            shellOutput: [
                "sysctl -n sysctl.proc_translated"
                    : .instant("0"),
                "id -un"
                    : .instant("user"),
                "which node"
                    : .instant("/opt/homebrew/bin/node"),
                "php -v"
                : .instant("""
                       PHP 8.1.10 (cli) (built: Sep  3 2022 12:09:27) (NTS)
                       Copyright (c) The PHP Group
                       Zend Engine v4.1.10, Copyright (c) Zend Technologies
                       with Zend OPcache v8.1.10, Copyright (c), by Zend Technologies
                    """),
                "ls /opt/homebrew/opt | grep php"
                    : .instant("php"),
                "ls /opt/homebrew/opt | grep php@"
                    : .instant("php@8.1"),
                "sudo /opt/homebrew/bin/brew services info nginx --json"
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
                "chmod +x /Users/nicoverbruggen/.config/phpmon/bin/pm81"
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
                "curl -s --max-time 5 '\(Constants.Urls.StableBuildCaskFile.absoluteString)' | grep version"
                    : .instant("version '5.6.2_976'")
            ],
            commandOutput: [
                "/opt/homebrew/bin/php-config --version": "8.1.10",
                "/opt/homebrew/bin/php -r echo ini_get('memory_limit');": "512M",
                "/opt/homebrew/bin/php -r echo ini_get('upload_max_filesize');": "512M",
                "/opt/homebrew/bin/php -r echo ini_get('post_max_size');": "512M",
                "/opt/homebrew/bin/php -r echo php_ini_scanned_files();"
                : """
                /opt/homebrew/etc/php/8.1/conf.d/error_log.ini,
                /opt/homebrew/etc/php/8.1/conf.d/ext-opcache.ini,
                /opt/homebrew/etc/php/8.1/conf.d/php-memory-limits.ini,
                /opt/homebrew/etc/php/8.1/conf.d/xdebug.ini
                """
            ]
        )
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
