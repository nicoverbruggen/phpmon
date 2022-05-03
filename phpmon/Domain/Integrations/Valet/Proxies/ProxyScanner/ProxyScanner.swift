//
//  ProxyScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 02/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol ProxyScanner {

    func resolveProxies(directoryPath: String) -> [ValetProxy]

}
