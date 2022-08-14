//
//  Shell+PATH.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension Shell {

    var PATH: String {
        let task = Process()
        task.launchPath = "/bin/zsh"

        // We need an interactive shell so the user's PATH is loaded in correctly
        task.arguments = ["--login", "-ilc", "echo $PATH"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
}
