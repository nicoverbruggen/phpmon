//
//  ValetSite+Security.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension ValetSite {
    /**
     Runs all metadata determinations for this site, with the blocking
     certificate read on the concurrent pool. Scanners construct sites with
     `makeDeterminations: false` and call this afterwards, so the main actor
     is never blocked while a batch of sites is resolved.
     */
    public func determine() async {
        self.favorited = container.favorites.contains(domain: favoriteSignature)

        let path = self.certificatePath
        let validator = CertificateValidator(container)
        apply(certificate: await offMain { validator.validateCertificate(at: path) })

        determineIsolated()
        determineComposerPhpVersion()
        determineDriver()
    }

    /// The path where this site's TLS certificate lives once it has been secured.
    private var certificatePath: String {
        return "~/.config/valet/Certificates/\(self.name).\(self.tld).crt"
    }

    /**
     Checks if a certificate file can be found in the `valet/Certificates` directory.
     Also tracks the expiry date of the certificate if it exists.

     This blocking variant reads the certificate on the caller's thread; use it for
     one-off refreshes (e.g. after securing/unsecuring a single site). Batch scans
     go through `determine()`, which reads the certificate off the main actor.
     */
    public func determineSecured() {
        apply(certificate: CertificateValidator(container).validateCertificate(at: certificatePath))
    }

    private func apply(certificate: (exists: Bool, expirationDate: Date?)) {
        if certificate.exists, let expiryDate = certificate.expirationDate, expiryDate < Date() {
            Log.warn("Certificate for \(self.name).\(self.tld) expired at: \(expiryDate). It should be renewed.")
        }

        // Persist the information for the list
        self.secured = certificate.exists
        self.certificateExpiryDate = certificate.expirationDate
    }

}
