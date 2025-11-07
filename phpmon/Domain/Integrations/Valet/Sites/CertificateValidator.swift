//
//  CertificateValidator.swift
//  PHP Monitor
//
//  Created by Assistant on 29/10/2025.
//  Copyright © 2023 Nico Verbruggen. All rights reserved.
//

import Foundation
import Security

/**
 A utility class for validating SSL certificates, including checking expiration dates.
 */
class CertificateValidator {

    /// The dependency container for file system access
    private let container: Container

    init(_ container: Container) {
        self.container = container
    }

    /**
     Checks if a certificate file exists and returns its expiration date.
     - Parameter certificatePath: Path to the certificate file (supports ~ for home directory)
     - Returns: A tuple containing (exists: Bool, expirationDate: Date?)
     */
    func validateCertificate(at certificatePath: String) -> (exists: Bool, expirationDate: Date?) {
        let exists = container.filesystem.fileExists(certificatePath)

        guard exists else {
            return (exists: false, expirationDate: nil)
        }

        let expirationDate = getCertificateExpirationDate(at: certificatePath)
        return (exists: true, expirationDate: expirationDate)
    }

    /**
     Loads certificate data from a file path using the filesystem abstraction.
     - Parameter path: The file path to the certificate
     - Returns: Certificate data as CFData, or nil if loading fails
     */
    private func loadCertificateData(from path: String) -> CFData? {
        do {
            let certificateString = try container.filesystem.getStringFromFile(path)

            // Remove PEM headers and footers, and whitespace
            let cleanedCertificate = certificateString
                .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let certificateData = Data(base64Encoded: cleanedCertificate) else {
                return nil
            }

            return certificateData as CFData
        } catch {
            Log.err("Failed to read certificate file at \(path): \(error)")
            return nil
        }
    }

    /**
     Gets detailed information about a certificate.
     - Parameter certificatePath: Path to the certificate file
     - Returns: A dictionary containing certificate details, or nil if the certificate couldn't be read
     */
    func getCertificateInfo(at certificatePath: String) -> [String: Any]? {
        guard let certificateData = loadCertificateData(from: certificatePath),
              let certificate = SecCertificateCreateWithData(nil, certificateData) else {
            return nil
        }

        guard let certDict = SecCertificateCopyValues(certificate, nil, nil) as? [String: Any] else {
            return nil
        }

        var info: [String: Any] = [:]

        // Extract common name
        if let subjectDict = certDict[kSecOIDX509V1SubjectName as String] as? [String: Any],
           let subjectArray = subjectDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
            for item in subjectArray {
                if let label = item[kSecPropertyKeyLabel as String] as? String,
                   label == "Common Name",
                   let value = item[kSecPropertyKeyValue as String] as? String {
                    info["commonName"] = value
                    break
                }
            }
        }

        // Extract expiration date
        if let validityDict = certDict[kSecOIDX509V1ValidityNotAfter as String] as? [String: Any],
           let validityValue = validityDict[kSecPropertyKeyValue as String] as? NSNumber {
            let expirationDate = Date(timeIntervalSinceReferenceDate: validityValue.doubleValue)
            info["expirationDate"] = expirationDate
        }

        // Extract issue date
        if let validityDict = certDict[kSecOIDX509V1ValidityNotBefore as String] as? [String: Any],
           let validityValue = validityDict[kSecPropertyKeyValue as String] as? NSNumber {
            let issueDate = Date(timeIntervalSinceReferenceDate: validityValue.doubleValue)
            info["issueDate"] = issueDate
        }

        return info
    }

    /**
     Gets the expiration date of a certificate.
     - Parameter certificatePath: Path to the certificate file
     - Returns: The expiration date, or nil if the certificate couldn't be read
     */
    func getCertificateExpirationDate(at certificatePath: String) -> Date? {
        guard let info = getCertificateInfo(at: certificatePath) else {
            return nil
        }

        return info["expirationDate"] as? Date
    }
}
