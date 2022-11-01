//
//  System.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

public func system(_ command: String) {
    let argsArray = command.split(separator: " ").map { String($0) }
    guard argsArray.isEmpty else { return  }
    let command = strdup(argsArray.first!)
    let args = argsArray.map { strdup($0) } + [nil]
    posix_spawn(nil, command, nil, nil, args, nil)
    return
}
