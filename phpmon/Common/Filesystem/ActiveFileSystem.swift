//
//  FS.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 08/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use an injected `Container` instance to access this instead.")
var FileSystem: FileSystemProtocol {
    return App.shared.container.filesystem
}
