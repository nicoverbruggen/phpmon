//
//  ValetProxy.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2022.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
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

    convenience init?(_ container: Container, _ configuration: NginxConfigurationFile, makeDeterminations: Bool = true) {
        guard let proxy = configuration.proxy else { return nil }
        self.init(
            container,
            domain: configuration.domain,
            target: proxy,
            secure: false,
            tld: configuration.tld
        )

        if makeDeterminations {
            self.favorited = container.favorites.contains(domain: self.domain)
            self.determineSecured()
        }
    }

    // MARK: - ValetListable Protocol

    func getListableName() -> String {
        return self.domain
    }

    func getListableTLD() -> String {
        return self.tld
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

    /**
     Runs the metadata determinations for this proxy, with the blocking
     certificate read on the concurrent pool (see `ValetSite.determine()`).
     */
    func determine() async {
        self.favorited = container.favorites.contains(domain: self.domain)

        let path = self.certificatePath
        let validator = CertificateValidator(container)
        apply(certificate: await offMain { validator.validateCertificate(at: path) })
    }

    /// The path where this proxy's TLS certificate lives once it has been secured.
    private var certificatePath: String {
        return "~/.config/valet/Certificates/\(self.domain).\(self.tld).crt"
    }

    /**
     Blocking variant of the certificate check, for one-off refreshes (e.g. after
     securing/unsecuring a proxy). Batch scans go through `determine()`.
     */
    func determineSecured() {
        apply(certificate: CertificateValidator(container).validateCertificate(at: certificatePath))
    }

    private func apply(certificate: (exists: Bool, expirationDate: Date?)) {
        if certificate.exists, let expiryDate = certificate.expirationDate, expiryDate < Date() {
            Log.warn("Certificate for \(self.domain).\(self.tld) expired at: \(expiryDate). It should be renewed.")
        }

        // Persist the information for the list
        self.secured = certificate.exists
        self.certificateExpiryDate = certificate.expirationDate
    }

    func toggleFavorite() {
        self.favorited.toggle()
        container.favorites.toggle(domain: self.favoriteSignature)
    }

    func toggleSecure() async throws {
        try await ValetInteractor.shared.toggleSecure(proxy: self)
    }

    func remove() async throws {
        try await ValetInteractor.shared.remove(proxy: self)
    }
}
