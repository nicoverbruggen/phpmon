//
//  Shell.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 20/09/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Use an injected `Container` instance to access this instead.")
var Shell: ShellProtocol {
    return App.shared.container.shell
}
