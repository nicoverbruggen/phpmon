//
//  PhpInitFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 04/05/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class PhpInitializationFile {

    /// The file where this extension was located.
    let file: String

    /// The original string contained within the file when scanned.
    let raw: [String]

    /// The extensions found in this .ini file.
    let extensions: [PhpExtension]

    init(fileUrl: URL) {
        self.file = fileUrl.path

        let rawString = (try? String(contentsOf: fileUrl, encoding: .utf8)) ?? ""

        self.raw = rawString.components(separatedBy: "\n")

        self.extensions = PhpExtension.load(from: fileUrl)

        dump(self)

        // TODO: Actually parse the .ini file
        // Parsing the file could be done like this gist:
        // https://gist.github.com/jetmind/f776c0d223e4ac6aec1ff9389e874553
    }

}
