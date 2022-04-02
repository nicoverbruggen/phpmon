//
//  NginxConfiguration.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class NginxConfiguration {
    
    var contents: String!
    
    init(filePath: String) {
        self.contents = try! String(contentsOfFile: filePath
            .replacingOccurrences(of: "~", with: "/Users/\(Paths.whoami)")
        )
    }
    
    /**
     Retrieves what address this domain is proxying.
     */
    lazy var proxy: String? = {
        let regex = try! NSRegularExpression(
            pattern: #"proxy_pass (?<proxy>.*:\d*);"#,
            options: []
        )
        
        guard let match = regex.firstMatch(in: contents, range: NSMakeRange(0, contents.count))
            else { return nil }
        
        return contents[Range(match.range(withName: "proxy"), in: contents)!]
    }()
        
    /**
     Retrieves which isolated version is active for this domain.
     */
    lazy var isolatedVersion: String? = {
        let regex = try! NSRegularExpression(
            // PHP versions have (so far) never needed multiple digits for version numbers
            pattern: #"(ISOLATED_PHP_VERSION=(php)?(@)?)((?<major>\d)(.)?(?<minor>\d))"#,
            options: []
        )
        
        guard let match = regex.firstMatch(in: contents, range: NSMakeRange(0, contents.count))
            else { return nil }

        let major: String = contents[Range(match.range(withName: "major"), in: contents)!],
            minor: String = contents[Range(match.range(withName: "minor"), in: contents)!]
        
        return "\(major).\(minor)"
    }()
}
