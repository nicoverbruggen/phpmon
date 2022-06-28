//
//  NginxConfigurationFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class NginxConfigurationFile: CreatedFromFile {

    /// Contents of the Nginx file in question, as a string.
    var contents: String!

    /// The name of the domain, usually derived from the name of the file.
    var domain: String

    /// The TLD of the domain, usually derived from the name of the file.
    var tld: String

    /** Resolves an nginx configuration file (.conf) */
    static func from(filePath: String) -> Self? {
        let path = filePath.replacingOccurrences(
            of: "~",
            with: "/Users/\(Paths.whoami)"
        )

        do {
            let fileContents = try String(contentsOfFile: path)

            return Self.init(
                path: path,
                contents: fileContents
            )
        } catch {
            Log.warn("Could not read the nginx configuration file at: `\(filePath)`")
            return nil
        }
    }

    required init(path: String, contents: String) {
        let domain = String(path.split(separator: "/").last!)
        let tld = String(domain.split(separator: ".").last!)

        self.contents = contents
        self.domain = domain.replacingOccurrences(of: ".\(tld)", with: "")
        self.tld = tld
    }

    /** Retrieves what address this domain is proxying. */
    lazy var proxy: String? = {
        let regex = try! NSRegularExpression(
            pattern: #"proxy_pass (?<proxy>.*:\d*)(\/*);"#,
            options: []
        )

        guard let match = regex.firstMatch(in: contents, range: NSRange(location: 0, length: contents.count))
            else { return nil }

        return contents[Range(match.range(withName: "proxy"), in: contents)!]
    }()

    /** Retrieves which isolated version is active for this domain (if applicable). */
    lazy var isolatedVersion: String? = {
        let regex = try! NSRegularExpression(
            // PHP versions have (so far) never needed multiple digits for version numbers
            pattern: #"(ISOLATED_PHP_VERSION=(php)?(@)?)((?<major>\d)(.)?(?<minor>\d))"#,
            options: []
        )

        guard let match = regex.firstMatch(in: contents, range: NSRange(location: 0, length: contents.count))
            else { return nil }

        let major: String = contents[Range(match.range(withName: "major"), in: contents)!],
            minor: String = contents[Range(match.range(withName: "minor"), in: contents)!]

        return "\(major).\(minor)"
    }()
}
