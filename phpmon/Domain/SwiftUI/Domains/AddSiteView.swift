//
//  AddSiteView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 18/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI
import AppKit

private struct PathControl: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSPathControl {
        let control = NSPathControl()
        control.isEditable = false
        control.url = url
        control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        control.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return control
    }

    func updateNSView(_ nsView: NSPathControl, context: Context) {
        nsView.url = url
    }
}

struct AddSiteView: View {
    let path: String

    let tld: String
    var onCancel: () -> Void
    var onConfirm: (String, Bool) -> Void
    var domainExists: (String) -> Bool

    @State private var domainName: String
    @State private var secure: Bool = false

    init(
        path: String,
        tld: String,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (String, Bool) -> Void,
        domainExists: @escaping (String) -> Bool
    ) {
        self.path = path
        self.tld = tld
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.domainExists = domainExists

        let initial = String(path
            .split(separator: "/")
            .last ?? "")
            .lowercased()

        _domainName = State(initialValue: initial)
    }

    private var validationError: String? {
        if domainName.isEmpty {
            return "domain_list.add.errors.empty".localized
        }
        if domainExists(domainName) {
            return "domain_list.add.errors.already_exists".localized
        }
        return nil
    }

    private var isValid: Bool { validationError == nil && !domainName.isEmpty }

    private var preview: String {
        guard !domainName.isEmpty else {
            return "domain_list.add.empty_fields".localized
        }
        return "domain_list.add.folder_available".localized(
            secure ? "https" : "http",
            domainName,
            tld
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                Text("domain_list.add.link_folder")
                    .font(.system(size: 16, weight: .bold, design: .default))

                PathControl(url: URL(fileURLWithPath: path))
                    .frame(maxWidth: .infinity, maxHeight: 22)
                    .clipped()

                TextField("domain_list.add.domain_name_placeholder".localized, text: Binding(
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
                        title: "domain_list.add.create_link".localized,
                        imageName: "IconLinked",
                        action: { onConfirm(domainName, secure) }
                    )
                    .disabled(!isValid)
                }.padding(20)
            }

        }
        .frame(width: 550)
    }
}

#Preview {
    AddSiteView(
        path: "/Users/nico/Code/my-website",
        tld: "test",
        onCancel: {},
        onConfirm: { _, _ in },
        domainExists: { _ in false }
    ).frame(height: 350)
}
