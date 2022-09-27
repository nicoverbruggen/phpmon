//
//  Shell+PATH.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/08/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

extension LegacyShell {

    var PATH: String {
        let task = Process()
        task.launchPath = "/bin/zsh"

        let command = Filesystem.fileExists("~/.zshrc")
            // source the user's .zshrc file if it exists to complete $PATH
            ? ". ~/.zshrc && echo $PATH"
            // otherwise, non-interactive mode is sufficient
            : "echo $PATH"

        task.arguments = ["--login", "-lc", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
}
