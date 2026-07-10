//
//  ValetSite+Security.swift
//  PHP Monitor
//
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import Foundation

extension ValetSite {

    /**
     The raw, `Sendable` contents of the files that describe a site's metadata:
     the TLS certificate, the Nginx (isolation) configuration, `composer.json`
     and the `.valetrc`/`.valetphprc` files.

     All blocking file I/O happens when this snapshot is created; the main-actor
     `ValetSite` model is then updated from the snapshot without further I/O
     (see `determine()`). Creating a snapshot synchronously is only acceptable
     against fake containers, where the reads resolve instantly.
     */
    nonisolated struct FileSnapshot: Sendable {
        let certificateExists: Bool
        let certificateExpiryDate: Date?
        let nginxConfigContents: String?
        let composerJsonContents: String?
        let valetRCContents: String?
        let valetPhpRCContents: String?

        init(_ container: Container, name: String, tld: String, absolutePath: String) {
            let certificate = CertificateValidator(container)
                .validateCertificate(at: Self.certificatePath(name: name, tld: tld))

            self.certificateExists = certificate.exists
            self.certificateExpiryDate = certificate.expirationDate
            self.nginxConfigContents = Self.read(container, "~/.config/valet/Nginx/\(name).\(tld)")
            self.composerJsonContents = Self.read(container, "\(absolutePath)/composer.json")
            self.valetRCContents = Self.read(container, "\(absolutePath)/.valetrc")
            self.valetPhpRCContents = Self.read(container, "\(absolutePath)/.valetphprc")
        }

        /// The path where a site's TLS certificate lives once it has been secured.
        static func certificatePath(name: String, tld: String) -> String {
            return "~/.config/valet/Certificates/\(name).\(tld).crt"
        }

        private static func read(_ container: Container, _ path: String) -> String? {
            guard container.filesystem.fileExists(path) else {
                return nil
            }

            return try? container.filesystem.getStringFromFile(path)
        }
    }

    /**
     Runs all metadata determinations for this site, with the blocking file
     reads (certificate, Nginx config, composer.json, .valetrc/.valetphprc)
     on the concurrent pool. Scanners construct sites with
     `makeDeterminations: false` and call this afterwards, so the main actor
     is never blocked while a batch of sites is resolved.
     */
    public func determine() async {
        let (container, name, tld, absolutePath) = (self.container, self.name, self.tld, self.absolutePath)

        let snapshot = await offMain {
            FileSnapshot(container, name: name, tld: tld, absolutePath: absolutePath)
        }

        apply(snapshot)
    }

    /**
     Re-checks only the TLS certificate (off the main actor). Used after
     securing or unsecuring a single site; full scans go through `determine()`.
     */
    public func refreshSecuredStatus() async {
        let (container, name, tld) = (self.container, self.name, self.tld)

        let certificate = await offMain {
            CertificateValidator(container)
                .validateCertificate(at: FileSnapshot.certificatePath(name: name, tld: tld))
        }

        apply(certificate: certificate)
    }

    /**
     Applies a file snapshot to the model. Runs on the main actor and performs
     no I/O: everything is parsed from the snapshot's strings.
     */
    func apply(_ snapshot: FileSnapshot) {
        self.favorited = container.favorites.contains(domain: favoriteSignature)

        apply(certificate: (snapshot.certificateExists, snapshot.certificateExpiryDate))

        determineIsolated(nginxConfigContents: snapshot.nginxConfigContents)
        determineComposerPhpVersion(
            composerJsonContents: snapshot.composerJsonContents,
            valetRCContents: snapshot.valetRCContents,
            valetPhpRCContents: snapshot.valetPhpRCContents
        )
        determineDriver()
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
