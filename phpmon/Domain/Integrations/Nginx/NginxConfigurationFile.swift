//
//  NginxConfigurationFile.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 15/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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
    static func from(
        _ container: Container,
        filePath: String,
    ) -> Self? {
        let path = filePath.replacing("~", with: container.paths.homePath)

        do {
            let fileContents = try String(contentsOfFile: path)

            return Self.init(path: path, contents: fileContents)
        } catch {
            Log.warn("Could not read the nginx configuration file at: `\(filePath)`")
            return nil
        }
    }

    required init(path: String, contents: String) {
        let domain = String(path.split(separator: "/").last!)
        let tld = String(domain.split(separator: ".").last!)

        self.contents = contents
        self.domain = domain.replacing(".\(tld)", with: "")
        self.tld = tld
    }

    /** Retrieves what address this domain is proxying. */
    lazy var proxy: String? = {
        let regex = try! NSRegularExpression(
            pattern: #"proxy_pass (?<proxy>.*:\d*)(\/*);"#,
            options: []
        )

        guard let match = regex.firstMatch(in: contents, range: NSRange(contents.startIndex..., in: contents)),
              let range = Range(match.range(withName: "proxy"), in: contents)
            else { return nil }

        return String(contents[range])
    }()

    /** Retrieves which isolated version is active for this domain (if applicable). */
    lazy var isolatedVersion: String? = {
        let regex = try! NSRegularExpression(
            // PHP versions have (so far) never needed multiple digits for version numbers
            pattern: #"(ISOLATED_PHP_VERSION=(php)?(@)?)((?<major>\d)(.)?(?<minor>\d))"#,
            options: []
        )

        guard let match = regex.firstMatch(in: contents, range: NSRange(contents.startIndex..., in: contents)),
              let majorRange = Range(match.range(withName: "major"), in: contents),
              let minorRange = Range(match.range(withName: "minor"), in: contents)
            else { return nil }

        return "\(String(contents[majorRange])).\(String(contents[minorRange]))"
    }()
}
