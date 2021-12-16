//
//  VersionExtractor.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 16/12/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

class VersionExtractor {
    
    public static func from(_ string: String) -> String? {
        let regex = try! NSRegularExpression(
            pattern: #"Laravel Valet (?<version>(\d+)(.)(\d+)((.)(\d+))?)"#,
            options: []
        )
        
        let match = regex.matches(
            in: string,
            options: [],
            range: NSMakeRange(0, string.count)
        ).first
        
        guard let match = match else {
            return nil
        }
        
        let range = Range(
            match.range(withName: "version"),
            in: string
        )!
        
        return String(string[range])
    }
    
}
