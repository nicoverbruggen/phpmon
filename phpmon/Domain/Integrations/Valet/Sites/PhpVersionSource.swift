//
//  VersionSource.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/01/2023.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

enum PhpVersionSource: String {
    case unknown
    case require
    case platform
    case valetphprc
    case valetrc
}
