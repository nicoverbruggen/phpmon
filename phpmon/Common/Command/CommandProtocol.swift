//
//  CommandProtocol.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/10/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol CommandProtocol {

    /**
     Immediately executes a command.

     - Parameter path: The path of the command or program to invoke.
     - Parameter arguments: A list of arguments that are passed on.
     - Parameter trimNewlines: Removes empty new line output.
     */
    func execute(path: String, arguments: [String], trimNewlines: Bool) -> String

}
