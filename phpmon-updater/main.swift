//
//  AppDelegate.swift
//  PHP Monitor Updater
//
//  Created by Nico Verbruggen on 01/02/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Cocoa

// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
