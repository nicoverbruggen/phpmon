//
//  DomainListVC+Certs.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import NVAlert
import Foundation

extension DomainListVC {
    func checkForCertificateRenewal() {
        // Check for expired certificates
        let expired = domains.filter { item in
            if let expiry = item.getListableCertificateExpiryDate() {
                return expiry < Date()
            }
            return false
        }

        // If no expired domains exist, skip this alert
        if expired.isEmpty {
            return
        }

        // An easily accessible list of domains
        let domainListing = "- " + expired.map {
            $0.getListableName() + "." + $0.getListableTLD()
        }.joined(separator: "\n- ")

        // Ensure the window is accessible
        guard let window = App.shared.domainListWindowController?.window else {
            return
        }

        // Present the modal attached to the window
        Task { @MainActor in
            // Show an alert
            return NVAlert().withInformation(
                title: "cert_alert.title".localized,
                subtitle: "cert_alert.description".localized,
                description: "cert_alert.domains".localized(domainListing)
            )
            .withPrimary(text: "cert_alert.renew".localized, action: { vc in
                Task { await self.renewCertificates(expired) }
                vc.close(with: .OK)
            })
            .withSecondary(text: "cert_alert.cancel".localized, action: { vc in
                vc.close(with: .abort)
            })
            .presentAsSheet(attachedTo: window)
        }
    }

    public func renewCertificates(_ expired: [ValetListable]) async {
        waitAndExecute {
            for domain in expired {
                // Unsecure domain first
                try? await domain.toggleSecure()

                // Resecure if unsecured
                if !domain.getListableSecured() {
                    try? await domain.toggleSecure()
                }
            }
        } completion: {
            Task {
                await delay(seconds: 1)
                await self.reloadDomainsWithoutUI()
            }
        }
    }
}
