//
//  ValetConfiguration.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/11/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetConfiguration: Decodable {
    let tld: String
    let paths: [String]
    let loopback: String
}


