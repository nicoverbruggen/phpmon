//
//  ValetProxyScanner.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetProxyScanner: ProxyScanner {
    func resolveProxies(directoryPath: String) -> [ValetProxy] {
        return try! FileManager
            .default
            .contentsOfDirectory(atPath: directoryPath)
            .filter {
                // Skip .DS_Store files
                return $0 != ".DS_Store"
            }
            .map {
                return NginxConfiguration.init(filePath: "\(directoryPath)/\($0)")
            }
            .filter {
                return $0.proxy != nil
            }
            .map {
                return ValetProxy($0)
            }
    }
}
