//
//  ValetProxy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2022.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation

class ValetProxy: ValetListable {
    var domain: String
    var tld: String
    var target: String
    var secured: Bool = false

    var certificateExpiryDate: Date?
    var isCertificateExpired: Bool {
        guard let certificateExpiryDate = certificateExpiryDate else {
            return false
        }
        return certificateExpiryDate < Date()
    }

    var favorited: Bool = false
    var favoriteSignature: String {
        "proxy:domain:\(domain).\(tld)|target:\(target)"
    }

    var container: Container

    init(_ container: Container, domain: String, target: String, secure: Bool, tld: String) {
        self.container = container
        self.domain = domain
        self.tld = tld
        self.target = target
        self.secured = false
    }

    convenience init(_ container: Container, _ configuration: NginxConfigurationFile) {
        self.init(
            container,
            domain: configuration.domain,
            target: configuration.proxy!,
            secure: false,
            tld: configuration.tld
        )

        self.favorited = container.favorites.contains(domain: self.domain)
        self.determineSecured()
    }

    // MARK: - ValetListable Protocol

    func getListableName() -> String {
        return self.domain
    }

    func getListableSecured() -> Bool {
        return self.secured
    }

    func getListableCertificateExpiryDate() -> Date? {
        return self.certificateExpiryDate
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

    func getListableFavorited() -> Bool {
        return self.favorited
    }

    // MARK: - Interactions

    func determineSecured() {
        let certificatePath = "~/.config/valet/Certificates/\(self.domain).\(self.tld).crt"

        let (exists, expiryDate) = CertificateValidator(container)
            .validateCertificate(at: certificatePath)

        if exists, let expiryDate {
            Log.info("Certificate for \(self.domain).\(self.tld) expires at: \(expiryDate).")
        } else {
            Log.info("No certificate for \(self.domain).\(self.tld).")
        }

        // Persist the information for the list
        self.secured = exists
        self.certificateExpiryDate = expiryDate
    }

    func toggleFavorite() {
        self.favorited.toggle()
        container.favorites.toggle(domain: self.favoriteSignature)
    }

    func toggleSecure() async throws {
        try await ValetInteractor.shared.toggleSecure(proxy: self)
    }

    func remove() async {
        try! await ValetInteractor.shared.remove(proxy: self)
    }
}
