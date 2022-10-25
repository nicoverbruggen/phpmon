//
//  DomainListable.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 12/04/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

protocol DomainListable {

    func getListableName() -> String

    func getListableSecured() -> Bool

    func getListableAbsolutePath() -> String

    func getListablePhpVersion() -> String

    func getListableKind() -> String

    func getListableType() -> String

    func getListableUrl() -> URL?

}

extension ValetSite {

    func getListableName() -> String {
        return self.name
    }

    func getListableSecured() -> Bool {
        return self.secured
    }

    func getListableAbsolutePath() -> String {
        return self.absolutePath
    }

    func getListablePhpVersion() -> String {
        return self.servingPhpVersion
    }

    func getListableKind() -> String {
        return (self.aliasPath == nil) ? "linked" : "parked"
    }

    func getListableType() -> String {
        return self.driver ?? "ZZZ"
    }

    func getListableUrl() -> URL? {
        return URL(string: "\(self.secured ? "https://" : "http://")\(self.name).\(Valet.shared.config.tld)")
    }

}
