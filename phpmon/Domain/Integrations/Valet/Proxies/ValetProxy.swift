//
//  ValetProxy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2022.
//  Copyright © 2022 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetProxy: ValetListable {
    var domain: String
    var tld: String
    var target: String
    var secured: Bool = false

    init(domain: String, target: String, secure: Bool, tld: String) {
        self.domain = domain
        self.tld = tld
        self.target = target
        self.secured = false
    }

    convenience init(_ configuration: NginxConfigurationFile) {
        self.init(
            domain: configuration.domain,
            target: configuration.proxy!,
            secure: false,
            tld: configuration.tld
        )
        self.determineSecured()
    }

    // MARK: - ValetListable Protocol

    func getListableName() -> String {
        return self.domain
    }

    func getListableSecured() -> Bool {
        return self.secured
    }

    func getListableAbsolutePath() -> String {
        return self.domain
    }

    func getListablePhpVersion() -> String {
        return ""
    }

    func getListableKind() -> String {
        return "proxy"
    }

    func getListableType() -> String {
        return "proxy"
    }

    func getListableUrl() -> URL? {
        return URL(string: "\(self.secured ? "https://" : "http://")\(self.domain).\(self.tld)")
    }

    // MARK: - Interactions

    func determineSecured() {
        self.secured = FileSystem.fileExists("~/.config/valet/Certificates/\(self.domain).\(self.tld).key")
    }

    func toggleSecure() async throws {
        try await ValetInteractor.shared.toggleSecure(proxy: self)
    }

    func remove() async {
        try! await ValetInteractor.shared.remove(proxy: self)
    }
}
