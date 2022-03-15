//
//  NginxConfigParser.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class NginxConfigParser {
    
    var contents: String!
    
    init(filePath: String) {
        self.contents = try! String(contentsOfFile: filePath)
    }
        
    public func isolatedVersion() -> String? {
        let regex = try! NSRegularExpression(
            pattern: #"(ISOLATED_PHP_VERSION=(php@)?)((?<major>\d)(.)?(?<minor>\d))"#,
            options: []
        )
        
        let match = regex.firstMatch(in: contents, range: NSMakeRange(0, contents.count))
        
        if match == nil {
            return nil
        }
        
        let majorRange = Range(match!.range(withName: "major"), in: contents)!
        let minorRange = Range(match!.range(withName: "minor"), in: contents)!
        
        let major: String = contents[majorRange]
        let minor: String = contents[minorRange]
        
        return "\(major).\(minor)"
    }
}
