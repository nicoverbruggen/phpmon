//
//  AppDelegate.swift
//  PHP Monitor Self-Updater
//
//  Created by Nico Verbruggen on 01/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa
import NVAppUpdater

let delegate = SelfUpdater(
    appName: "PHP Monitor",
    bundleIdentifiers: [
        "com.nicoverbruggen.phpmon.eap",
        "com.nicoverbruggen.phpmon.dev",
        "com.nicoverbruggen.phpmon"
    ],
    selfUpdaterPath: "~/.config/phpmon/updater"
)

NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
