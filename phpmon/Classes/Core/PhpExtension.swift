//
//  PhpExtension.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 31/01/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

/**
 A PHP extension that was detected in the php.ini file.
 Please note that the extension may be disabled.
 
 - Note: You need to know more about regular expressions to be able to deal with these NSRegularExpression
 instances. You can find more information here: https://nshipster.com/swift-regular-expressions/
 */
class PhpExtension {
    var file: String
    var line: String
    var name: String
    var enabled: Bool
    
    init(_ line: String, file: String) {
        let regex = try! NSRegularExpression(pattern: #"^(extension=|zend_extension=|; extension=|; zend_extension=)"(?<name>[a-zA-Z]*).so"$"#, options: [])
        let match = regex.matches(in: line, options: [], range: NSMakeRange(0, line.count)).first
        let range = Range(match!.range(withName: "name"), in: line)!
        
        self.line = line
        self.name = line[range]
        self.enabled = !line.contains(";")
        self.file = file
    }
    
    public func toggle() {
        Actions.sed(
            file: self.file,
            original: self.line,
            replacement: self.enabled ? "; \(self.line)" : self.line.replacingOccurrences(of: "; ", with: "")
        )
        self.enabled = !self.enabled
    }
    
    static func load(from path: URL) -> [PhpExtension] {
        let file = try! String(contentsOf: path, encoding: .utf8)
        
        return file.components(separatedBy: "\n")
            .filter({ (line) -> Bool in
                return line.range(
                    of: #"^(extension=|zend_extension=|; extension=|; zend_extension=)"[a-zA-Z]*.so"$"#,
                    options: .regularExpression
                ) != nil
            })
            .map { (line) -> PhpExtension in
                return PhpExtension(line, file: path.path)
            }
    }
}
