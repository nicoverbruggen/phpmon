//
//  AddProxyView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct AddProxyView: View {
    let tld: String
    var onCancel: () -> Void
    var onConfirm: (String, String, Bool) -> Void
    var domainExists: (String) -> Bool

    @State private var domainName: String = ""
    @State private var proxySubject: String = "http://127.0.0.1:80"
    @State private var secure: Bool = false

    private var validationError: String? {
        if domainName.isEmpty {
            return "domain_list.add.errors.empty".localized
        }
        if proxySubject.isEmpty {
            return "domain_list.add.errors.empty_proxy".localized
        }
        if proxySubject.range(of: #"(http:\/\/|https:\/\/)(.+)(:)(\d+)$"#, options: .regularExpression) == nil {
            return "domain_list.add.errors.subject_invalid".localized
        }
        if domainExists(domainName) {
            return "domain_list.add.errors.already_exists".localized
        }
        return nil
    }

    private var isValid: Bool { validationError == nil }

    private var preview: String {
        guard !proxySubject.isEmpty, !domainName.isEmpty else {
            return "domain_list.add.empty_fields".localized
        }
        let key = proxySubject.starts(with: "https://")
            ? "domain_list.add.proxy_https_warning"
            : "domain_list.add.proxy_available"
        return key.localized(
            proxySubject,
            secure ? "https" : "http",
            domainName,
            tld
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("domain_list.add.set_up_proxy")
                    .font(.system(size: 16, weight: .bold, design: .default))

                Text("domain_list.add.proxy_subject")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("", text: Binding(
                    get: { proxySubject },
                    set: { proxySubject = $0.replacing(" ", with: "-") }
                ))

                Text("domain_list.add.domain_name")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("", text: Binding(
                    get: { domainName },
                    set: { domainName = $0.replacing(" ", with: "-") }
                ))

                Text(preview)
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))

                Toggle(
                    "domain_list.add.secure_after_creation".localized(domainName, tld),
                    isOn: $secure
                )

                Text("domain_list.add.secure_description")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                if let error = validationError {
                    ErrorView(message: error)
                }

                if validationError != nil {
                    Divider()
                }

                HStack {
                    Button("domain_list.add.cancel".localized) {
                        onCancel()
                    }
                    Spacer()
                    SimpleButton(
                        title: "domain_list.add.create_proxy".localized,
                        imageName: "IconProxy",
                        action: { onConfirm(domainName, proxySubject, secure) }
                    )
                    .disabled(!isValid)
                }.padding(20)
            }
        }
        .frame(width: 550)
    }
}

#Preview {
    AddProxyView(
        tld: "test",
        onCancel: {},
        onConfirm: { _, _, _ in },
        domainExists: { _ in false }
    )
}
