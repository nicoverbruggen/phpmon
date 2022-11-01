//
//  EmptyProxyScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 01/11/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class EmptyProxyScanner: ProxyScanner {
    func resolveProxies(directoryPath: String) -> [ValetProxy] {
        return []
    }
}
