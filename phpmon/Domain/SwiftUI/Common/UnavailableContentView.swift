//
//  NoDomainsView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 19/03/2024.
//  Copyright © 2024 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct UnavailableContentView: View {
    var title: String
    var description: String
    var icon: String
    var button: String?
    var action: (() -> Void)?

    init(
        title: String,
        description: String,
        icon: String,
        button: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.button = button
        self.action = action
    }

    var body: some View {
        Group {
            VStack(spacing: 15) {
                Image(systemName: self.icon)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color.appPrimary)
                    .padding(.bottom, 10)
                Text(self.title)
                    .font(.system(size: 18, weight: .bold))

                Text(self.description)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)

                if self.button != nil {
                    Button(self.button!) {
                        self.action!()
                    }.buttonStyle(.custom)
                }
            }
        }
        .padding(30)
        .frame(maxWidth: 400)
    }
}

#Preview {
    UnavailableContentView(
        title: "domain_list.domains_empty.title".localized,
        description: "domain_list.domains_empty.desc".localized,
        icon: "globe",
        button: "domain_list.domains_empty.button".localized,
        action: {}
    )
}
