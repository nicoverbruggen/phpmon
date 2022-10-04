//
//  Testables.swift
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
}

// swiftlint:disable colon trailing_comma
class Testables {
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
                "id -un"
                    : .instant("username"),
                "which node"
                    : .instant("/opt/homebrew/bin/node"),
                "php -v"
                : .instant(ShellStrings.phpVersion),
                "ls /opt/homebrew/opt | grep php"
                    : .instant("php"),
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
                "/opt/homebrew/bin/brew info php --json"
                    : .instant(ShellStrings.brewJson)
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

    static let brewJson = """
        [
        {
            "name":"php",
            "full_name":"php",
            "tap":"homebrew/core",
            "oldname":null,
            "aliases":[
                "php@8.0"
            ],
            "versioned_formulae":[
                "php@7.4",
                "php@7.3",
                "php@7.2"
            ],
            "desc":"General-purpose scripting language",
            "license":"PHP-3.01",
            "homepage":"https://www.php.net/",
            "versions":{
                "stable":"8.0.2",
                "head":"HEAD",
                "bottle":true
            },
            "urls":{
                "stable":{
                    "url":"https://www.php.net/distributions/php-8.0.2.tar.xz",
                    "tag":null,
                    "revision":null
                }
            },
            "revision":0,
            "version_scheme":0,
            "bottle":{
                "stable":{
                    "rebuild":0,
                    "cellar":"/opt/homebrew/Cellar",
                    "prefix":"/opt/homebrew",
                    "root_url":"https://homebrew.bintray.com/bottles",
                    "files":{
                        "arm64_big_sur":{
                            "url":"https://homebrew.bintray.com/bottles/php-8.0.2.arm64_big_sur.bottle.tar.gz",
                            "sha256":"cbefa1db73d08b9af4593a44512b8d727e43033ee8517736bae5f16315501b12"
                        },
                        "big_sur":{
                            "url":"https://homebrew.bintray.com/bottles/php-8.0.2.big_sur.bottle.tar.gz",
                            "sha256":"6857142e12254b15da4e74c2986dd24faca57dac8d467b04621db349e277dd63"
                        },
                        "catalina":{
                            "url":"https://homebrew.bintray.com/bottles/php-8.0.2.catalina.bottle.tar.gz",
                            "sha256":"b651611134c18f93fdf121a4277b51b197a896a19ccb8020289b4e19e0638349"
                        },
                        "mojave":{
                            "url":"https://homebrew.bintray.com/bottles/php-8.0.2.mojave.bottle.tar.gz",
                            "sha256":"9583a51fcc6f804aadbb14e18f770d4fb4973deaed6ddc4770342e62974ffbca"
                        }
                    }
                }
            },
            "keg_only":false,
            "bottle_disabled":false,
            "options":[

            ],
            "build_dependencies":[
                "httpd",
                "pkg-config"
            ],
            "dependencies":[
                "apr",
                "apr-util",
                "argon2",
                "aspell",
                "autoconf",
                "curl",
                "freetds",
                "gd",
                "gettext",
                "glib",
                "gmp",
                "icu4c",
                "krb5",
                "libffi",
                "libpq",
                "libsodium",
                "libzip",
                "oniguruma",
                "openldap",
                "openssl@1.1",
                "pcre2",
                "sqlite",
                "tidy-html5",
                "unixodbc"
            ],
            "recommended_dependencies":[

            ],
            "optional_dependencies":[

            ],
            "uses_from_macos":[
                {
                    "xz":"build"
                },
                "bzip2",
                "libedit",
                "libxml2",
                "libxslt",
                "zlib"
            ],
            "requirements":[

            ],
            "conflicts_with":[

            ],
            "installed":[
                {
                "version": "8.1.10_1",
                "used_options": [

                ],
                "built_as_bottle": true,
                "poured_from_bottle": true,
                "runtime_dependencies": [],
                "installed_as_dependency": false,
                "installed_on_request": true
                }
            ],
            "linked_keg":"8.0.2",
            "pinned":false,
            "outdated":false,
            "deprecated":false,
            "deprecation_date":null,
            "deprecation_reason":null,
            "disabled":false,
            "disable_date":null,
            "disable_reason":null
        }
        ]
        """
}
