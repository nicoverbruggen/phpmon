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
                Text("The domain \"\(name).\(tld)\" is not secured.")
                    .fontWeight(.bold)
                DisclaimerView(
                    iconName: "info.circle.fill",
                    message: "Traffic is served by nginx over plain HTTP. Keep in mind that certain web features may not work correctly without a secure connection.",
                    color: Color.statusColorRed
                )
            } else {
                Text("The domain \"\(name).\(tld)\" is secured.")
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                if let expires {
                    Text("Because this domain has been secured with a certificate, traffic to this domain is served by nginx over HTTPS.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    if expires < Date() {
                        DisclaimerView(
                            iconName: "info.circle.fill",
                            message: "The certificate expired on \(expires.formatted()). You must renew it to continue using HTTPS without errors.",
                            color: Color.statusColorOrange
                        )
                    } else {
                        DisclaimerView(
                            iconName: "info.circle.fill",
                            message: "The certificate is valid. It will expire on \(expires.formatted()). At that point it will need to be renewed, but you will be notified.",
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
