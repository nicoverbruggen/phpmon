//
//  SecurePopoverView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 29/10/2025.
//  Copyright © 2025 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct SecurePopoverView: View {
    var container: Container {
        return App.shared.container
    }

    @State var name: String
    @State var tld: String
    @State var expires: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if expires == nil {
                Text("cert_popover.insecure_domain".localized("\(name).\(tld)"))
                    .fontWeight(.bold)
                DisclaimerView(
                    iconName: "info.circle.fill",
                    message: "cert_popover.insecure_domain_text".localized,
                    color: Color.statusColorRed
                )
            } else {
                Text("cert_popover.secure_domain".localized("\(name).\(tld)"))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                if let expires {
                    Text("cert_popover.secure_domain_traffic".localized)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    if expires < Date() {
                        DisclaimerView(
                            iconName: "exclamationmark.triangle.fill",
                            message: "cert_popover.secure_domain_expired".localized(expires.formatted()),
                            color: Color.statusColorOrange
                        )
                    } else {
                        DisclaimerView(
                            iconName: "checkmark.circle.fill",
                            message: "cert_popover.secure_domain_expiring_later".localized(expires.formatted()),
                            color: Color.statusColorGreen
                        )
                    }
                }
            }
        }.frame(width: 400, alignment: .center)
            .padding(20)
            .background(
                Color(NSColor.windowBackgroundColor)
                    .padding(-80)
            )
    }
}

#Preview("Example") {
    SecurePopoverView(
        name: "hello",
        tld: "test",
        expires: nil
    )
}
