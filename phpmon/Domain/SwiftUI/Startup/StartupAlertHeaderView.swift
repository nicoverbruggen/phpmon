//
//  StartupAlertHeaderView.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 25/02/2026.
//  Copyright © 2026 Nico Verbruggen. All rights reserved.
//

import SwiftUI

struct StartupAlertHeaderView: View {
    let titleText: String
    let subtitleText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(markdown: titleText)
                    .font(.system(size: 15, weight: .bold))
                    .textSelection(.enabled)
                Text(markdown: subtitleText)
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding(15)
        .padding(.top, 0)
    }
}

#Preview {
    StartupAlertHeaderView(
        titleText: "startup.errors.php_binary.title".localized,
        subtitleText: "startup.errors.php_binary.subtitle".localized
    )
    .frame(width: 460)
}
