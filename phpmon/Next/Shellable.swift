//
//  Shellable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 21/09/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol Shellable {
    typealias Output = String

    func syncPipe(_ command: String) -> Output

    func pipe(_ command: String) async -> Output
}
