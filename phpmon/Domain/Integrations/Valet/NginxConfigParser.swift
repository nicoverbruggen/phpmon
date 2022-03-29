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
        self.contents = try! String(contentsOfFile: filePath
            .replacingOccurrences(of: "~", with: "/Users/\(Paths.whoami)")
        )
    }
        
    lazy var isolatedVersion: String? = {
        let regex = try! NSRegularExpression(
            // PHP versions have (so far) never needed multiple digits for version numbers
            pattern: #"(ISOLATED_PHP_VERSION=(php)?(@)?)((?<major>\d)(.)?(?<minor>\d))"#,
            options: []
        )
        
        let match = regex.firstMatch(in: contents, range: NSMakeRange(0, contents.count))
        
        if match == nil {
            return nil
        }

        let major: String = contents[Range(match!.range(withName: "major"), in: contents)!]
        let minor: String = contents[Range(match!.range(withName: "minor"), in: contents)!]
        
        return "\(major).\(minor)"
    }()
}
